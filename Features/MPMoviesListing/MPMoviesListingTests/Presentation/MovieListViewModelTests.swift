//
//  MovieListViewModelTests.swift
//  MPMoviesListing
//
//  Created by mac on 08/08/2025.
//

import XCTest
import Combine
import MPCore
@testable import MPMoviesListing

/// Unit tests for MovieListViewModel using mock dependencies
final class MovieListViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var viewModel: MovieListViewModel!
    private var mockRepository: MockMovieRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Configure SwiftDataStack for testing
        do {
            SwiftDataStack.shared = try SwiftDataStack.forTesting(with: [LocalMovieModel.self, LocalGenreModel.self])
        } catch {
            XCTFail("Failed to configure SwiftDataStack for testing: \(error)")
        }
        
        mockRepository = MockMovieRepository()
                
        viewModel = MovieListViewModel(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_withRepository_initializesCorrectly() {
        // Arrange & Act
        let defaultViewModel = MovieListViewModel(repository: mockRepository)
        
        // Assert
        XCTAssertNotNil(defaultViewModel)
        XCTAssertEqual(defaultViewModel.viewMode, .grid)
        XCTAssertTrue(defaultViewModel.canLoadMore)
        XCTAssertTrue(defaultViewModel.movies.isEmpty)
        XCTAssertTrue(defaultViewModel.genres.isEmpty)
        XCTAssertTrue(defaultViewModel.searchText.isEmpty)
        XCTAssertFalse(defaultViewModel.isSearching)
        XCTAssertTrue(defaultViewModel.recentSearches.isEmpty)
        XCTAssertEqual(defaultViewModel.sortOption, .popularity)
        XCTAssertFalse(defaultViewModel.isFilteringOrSorting)
    }
    
    // MARK: - Initial Data Loading Tests
    
    func test_loadInitialData_withSuccessfulResponse_updatesStateAndData() {
        // Arrange
        let expectedMovies = [Movie.sample, Movie.sample2]
        let expectedGenres = [Genre.sample, Genre.sample2]
        
        mockRepository.getPopularMoviesResult = .success(expectedMovies)
        mockRepository.getGenresResult = .success(expectedGenres)
        
        let expectation = XCTestExpectation(description: "Initial data loaded")
        
        // Monitor state changes
        var receivedState: ViewModelState<(movies: [Movie], genres: [Genre])>?
        viewModel.$state
            .sink { state in
                receivedState = state
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadInitialData()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        
        // Verify state
        if case .success(let data) = receivedState {
            XCTAssertEqual(data.movies.count, expectedMovies.count)
            XCTAssertEqual(data.genres.count, expectedGenres.count)
            XCTAssertEqual(data.movies.first?.id, expectedMovies.first?.id)
            XCTAssertEqual(data.genres.first?.id, expectedGenres.first?.id)
        } else {
            XCTFail("Expected success state")
        }
        
        // Verify published properties
        XCTAssertEqual(viewModel.movies.count, expectedMovies.count)
        XCTAssertEqual(viewModel.genres.count, expectedGenres.count)
        XCTAssertFalse(viewModel.canLoadMore) // 2 movies >= 20? No, so should be false
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
        XCTAssertEqual(mockRepository.getGenresCallCount, 1)
    }
    
    func test_loadInitialData_withNetworkError_updatesStateToFailure() {
        // Arrange
        let repositoryError = RepositoryError.remote(.networkUnavailable)
        mockRepository.getPopularMoviesResult = .failure(repositoryError)
        mockRepository.getGenresResult = .success([Genre.sample])
        
        let expectation = XCTestExpectation(description: "Error state received")
        
        // Monitor state changes
        var receivedError: Error?
        viewModel.$state
            .sink { state in
                if case .failure(let error) = state {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadInitialData()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedError)
        XCTAssertTrue(receivedError is RepositoryError)
    }
    
    // MARK: - Pagination Tests
    
    func test_loadMore_withMoreMoviesAvailable_appendsMovies() {
        // Arrange
        let initialMovies = Array(repeating: Movie.sample, count: 20) // Full page
        let moreMovies = [Movie.sample2]
        
        mockRepository.getPopularMoviesResult = .success(initialMovies)
        mockRepository.getGenresResult = .success([Genre.sample])
        
        // Load initial data first
        let initialExpectation = XCTestExpectation(description: "Initial data loaded")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    initialExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadInitialData()
        wait(for: [initialExpectation], timeout: 5.0)
        
        // Setup for load more
        mockRepository.getPopularMoviesResult = .success(moreMovies)
        let loadMoreExpectation = XCTestExpectation(description: "More movies loaded")
        
        viewModel.$state
            .dropFirst(2) // skip first success (initial data success), loading states
            .sink { state in
                print(state)
                if case .success = state {
                    loadMoreExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadMore()
        
        // Assert
        wait(for: [loadMoreExpectation], timeout: 5.0)
        XCTAssertEqual(viewModel.movies.count, 21) // 20 + 1
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 2)
        XCTAssertFalse(viewModel.canLoadMore) // Only 1 movie in second page, less than 20
    }
    
    func test_loadMore_whenAlreadyLoading_doesNothing() {
        // Arrange
        mockRepository.shouldDelayResponse = true
        mockRepository.getPopularMoviesResult = .success([Movie.sample])
        mockRepository.getGenresResult = .success([Genre.sample])
        
        let loadingExpectation = XCTestExpectation(description: "Movies loaded")

        viewModel.$state
            .sink { state in
                if case .loading = state {
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadInitialData() // Start loading
        
        wait(for: [loadingExpectation], timeout: 5.0)

        // Act - Try to load more while already loading
        viewModel.loadMore()
        viewModel.loadMore() // Call multiple times
        
        // Assert - Should not trigger additional calls
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
    }
    
    func test_loadMore_whenCanLoadMoreIsFalse_doesNothing() {
        // Arrange
        viewModel.canLoadMore = false
        
        // Act
        viewModel.loadMore()
        
        // Assert
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 0)
    }
    
    // MARK: - View Mode Tests
    
    func test_toggleViewMode_switchesBetweenGridAndList() {
        // Arrange
        XCTAssertEqual(viewModel.viewMode, .grid)
        
        // Act & Assert - Toggle to list
        viewModel.toggleViewMode()
        XCTAssertEqual(viewModel.viewMode, .list)
        
        // Act & Assert - Toggle back to grid
        viewModel.toggleViewMode()
        XCTAssertEqual(viewModel.viewMode, .grid)
    }
    
    // MARK: - Search Tests
    
    func test_startSearch_withValidQuery_performsSearch() {
        // Arrange
        let searchQuery = "Action"
        let searchResults = [Movie.sample]
        
        mockRepository.searchMoviesResult = .success(searchResults)
        viewModel.searchText = searchQuery
        
        let expectation = XCTestExpectation(description: "Search completed")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.startSearch()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.movies.count, searchResults.count)
        XCTAssertEqual(mockRepository.searchMoviesCallCount, 1)
        XCTAssertTrue(viewModel.recentSearches.contains(searchQuery))
    }
    
    func test_startSearch_withEmptyQuery_endsSearch() {
        // Arrange
        viewModel.searchText = ""
        viewModel.isSearching = true
        
        // Act
        viewModel.startSearch()
        
        // Assert
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertEqual(mockRepository.searchMoviesCallCount, 0)
    }
    
    func test_endSearch_clearsSearchStateAndResetsData() {
        // Arrange
        viewModel.isSearching = true
        viewModel.searchText = "Action"
        
        // Act
        viewModel.endSearch()
        
        // Assert
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertTrue(viewModel.canLoadMore)
    }
    
    func test_performSearchWithQuery_updatesSearchTextAndStartsSearch() {
        // Arrange
        let searchQuery = "Comedy"
        let searchResults = [Movie.sample2]
        
        mockRepository.searchMoviesResult = .success(searchResults)
        
        let expectation = XCTestExpectation(description: "Search with query completed")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.performSearch(with: searchQuery)
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(viewModel.searchText, searchQuery)
        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.movies.count, searchResults.count)
    }
    
    func test_searchPagination_appendsMoreResults() {
        // Arrange
        let initialResults = Array(repeating: Movie.sample, count: 20)
        let moreResults = [Movie.sample2]
        
        viewModel.searchText = "Action"
        mockRepository.searchMoviesResult = .success(initialResults)
        
        // Start initial search
        let initialExpectation = XCTestExpectation(description: "Initial search completed")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    initialExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.startSearch()
        wait(for: [initialExpectation], timeout: 5.0)
        
        // Setup for pagination
        mockRepository.searchMoviesResult = .success(moreResults)
        let paginationExpectation = XCTestExpectation(description: "Search pagination completed")
        
        viewModel.$state
            .dropFirst(2) // skip first success (initial data success), loading states
            .sink { state in
                if case .success = state {
                    paginationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act - Load more search results
        viewModel.loadMore()
        
        // Assert
        wait(for: [paginationExpectation], timeout: 5.0)
        XCTAssertEqual(viewModel.movies.count, 21) // 20 + 1
        XCTAssertEqual(mockRepository.searchMoviesCallCount, 2)
    }
    
    func test_recentSearches_maintainsOrderAndLimit() {
        // Arrange
        let searches = (1...15).map { "Search \($0)" }
        
        // Act - Add searches
        for search in searches {
            viewModel.performSearch(with: search)
        }
        
        // Assert - Should only keep 10 recent searches, most recent first
        XCTAssertEqual(viewModel.recentSearches.count, 10)
        XCTAssertEqual(viewModel.recentSearches.first, "Search 15")
        XCTAssertEqual(viewModel.recentSearches.last, "Search 6")
    }
    
    func test_recentSearches_removiesDuplicates() {
        // Arrange
        let searchQuery = "Duplicate Search"
        
        // Act - Add same search multiple times
        viewModel.performSearch(with: searchQuery)
        viewModel.performSearch(with: "Other Search")
        viewModel.performSearch(with: searchQuery) // Duplicate
        
        // Assert - Should only appear once at the top
        XCTAssertEqual(viewModel.recentSearches.count, 2)
        XCTAssertEqual(viewModel.recentSearches.first, searchQuery)
        XCTAssertEqual(viewModel.recentSearches.last, "Other Search")
    }
    
    // MARK: - Filter and Sort Tests
    
    func test_applySortAndGenreFilter_withActiveFilter_appliesFilterAndSort() {
        // Arrange
        let sortOption = MovieSortOption.rating
        let genreFilter = GenreFilter(selectedGenreIds: [28, 35])
        let filteredResults = [Movie.sample]
        
        mockRepository.filterAndSortMoviesResult = .success(filteredResults)
        
        let expectation = XCTestExpectation(description: "Filter and sort applied")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.applySortAndGenreFilter(sortOption: sortOption, filter: genreFilter)
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(viewModel.sortOption, sortOption)
        XCTAssertEqual(viewModel.genreFilter, genreFilter)
        XCTAssertTrue(viewModel.isFilteringOrSorting)
        XCTAssertEqual(viewModel.movies.count, filteredResults.count)
        XCTAssertEqual(mockRepository.filterAndSortMoviesCallCount, 1)
    }
    
    func test_applySortAndGenreFilter_withDefaultSettings_refreshesNormalData() {
        // Arrange
        let sortOption = MovieSortOption.popularity // Default
        let genreFilter = GenreFilter() // Empty filter
        
        mockRepository.getPopularMoviesResult = .success([Movie.sample])
        mockRepository.getGenresResult = .success([Genre.sample])
        
        let expectation = XCTestExpectation(description: "Normal data refreshed")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.applySortAndGenreFilter(sortOption: sortOption, filter: genreFilter)
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertFalse(viewModel.isFilteringOrSorting)
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
        XCTAssertEqual(mockRepository.filterAndSortMoviesCallCount, 0)
    }
    
    func test_filterAndSortPagination_appendsMoreFilteredResults() {
        // Arrange
        let initialResults = Array(repeating: Movie.sample, count: 20)
        let moreResults = [Movie.sample2]
        let genreFilter = GenreFilter(selectedGenreIds: [28])
        
        mockRepository.filterAndSortMoviesResult = .success(initialResults)
        
        // Apply initial filter
        let initialExpectation = XCTestExpectation(description: "Initial filter applied")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    initialExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.applySortAndGenreFilter(sortOption: .rating, filter: genreFilter)
        wait(for: [initialExpectation], timeout: 5.0)
        
        // Setup for pagination
        mockRepository.filterAndSortMoviesResult = .success(moreResults)
        let paginationExpectation = XCTestExpectation(description: "Filter pagination completed")
        
        viewModel.$state
            .dropFirst(2) // skip first success (initial data success), loading states
            .sink { state in
                if case .success = state {
                    paginationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act - Load more filtered results
        viewModel.loadMore()
        
        // Assert
        wait(for: [paginationExpectation], timeout: 5.0)
        XCTAssertEqual(viewModel.movies.count, 21) // 20 + 1
        XCTAssertEqual(mockRepository.filterAndSortMoviesCallCount, 2)
    }
    
    // MARK: - Refresh Tests
    
    func test_refresh_inNormalMode_loadsInitialData() {
        // Arrange
        mockRepository.getPopularMoviesResult = .success([Movie.sample])
        mockRepository.getGenresResult = .success([Genre.sample])
        
        let expectation = XCTestExpectation(description: "Refresh completed")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.refresh()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
        XCTAssertEqual(mockRepository.getGenresCallCount, 1)
    }
    
    func test_refresh_inSearchMode_restartsSearch() {
        // Arrange
        viewModel.isSearching = true
        viewModel.searchText = "Action"
        
        mockRepository.searchMoviesResult = .success([Movie.sample])
        
        let expectation = XCTestExpectation(description: "Search refresh completed")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.refresh()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(mockRepository.searchMoviesCallCount, 1)
    }
    
    func test_refresh_inFilterMode_reappliesFilter() {
        // Arrange
        viewModel.isFilteringOrSorting = true
        viewModel.genreFilter = GenreFilter(selectedGenreIds: [28])
        
        mockRepository.filterAndSortMoviesResult = .success([Movie.sample])
        
        let expectation = XCTestExpectation(description: "Filter refresh completed")
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.refresh()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(mockRepository.filterAndSortMoviesCallCount, 1)
    }
    
    // MARK: - Utility Tests
    
    func test_getGenresForIds_returnsMatchingGenres() {
        // Arrange
        let genres = [
            Genre(id: 28, name: "Action"),
            Genre(id: 35, name: "Comedy"),
            Genre(id: 18, name: "Drama")
        ]
        viewModel.genres = genres
        
        // Act
        let actionGenres = viewModel.getGenres(for: [28])
        let multipleGenres = viewModel.getGenres(for: [28, 35])
        let noMatches = viewModel.getGenres(for: [999])
        
        // Assert
        XCTAssertEqual(actionGenres.count, 1)
        XCTAssertEqual(actionGenres.first?.name, "Action")
        
        XCTAssertEqual(multipleGenres.count, 2)
        XCTAssertTrue(multipleGenres.contains { $0.name == "Action" })
        XCTAssertTrue(multipleGenres.contains { $0.name == "Comedy" })
        
        XCTAssertTrue(noMatches.isEmpty)
    }
    
    // MARK: - Memory Management Tests
    
    func test_viewModel_deallocatesCorrectly() {
        // Arrange
        weak var weakViewModel = viewModel
        weak var weakRepository = mockRepository
        
        // Act
        viewModel = nil
        mockRepository = nil
        
        // Assert - Check for potential retain cycles
        XCTAssertNil(weakViewModel)
        XCTAssertNil(weakRepository)
    }
    
    // MARK: - State Management Tests
    
    func test_stateTransitions_followCorrectPattern() {
        // Arrange
        mockRepository.getPopularMoviesResult = .success([Movie.sample])
        mockRepository.getGenresResult = .success([Genre.sample])
        
        var stateTransitions: [ViewModelState<(movies: [Movie], genres: [Genre])>] = []
        
        viewModel.$state
            .sink { state in
                stateTransitions.append(state)
            }
            .store(in: &cancellables)
        
        let expectation = XCTestExpectation(description: "State transitions completed")
        
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadInitialData()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        
        // Verify state transition pattern: idle -> loading -> success
        XCTAssertTrue(stateTransitions.count >= 3)
        
        if case .idle = stateTransitions[0] {
            // Expected
        } else {
            XCTFail("First state should be idle")
        }
        
        if case .loading = stateTransitions[1] {
            // Expected
        } else {
            XCTFail("Second state should be loading")
        }
        
        if case .success = stateTransitions[2] {
            // Expected
        } else {
            XCTFail("Third state should be success")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func test_errorStates_propagateCorrectly() {
        // Arrange
        let useCaseError = UseCaseError.networkError
        mockRepository.searchMoviesResult = .failure(useCaseError)
        
        viewModel.searchText = "Action"
        
        let expectation = XCTestExpectation(description: "Error state received")
        var receivedError: Error?
        
        viewModel.$state
            .sink { state in
                if case .failure(let error) = state {
                    receivedError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.startSearch()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedError)
        XCTAssertTrue(receivedError is UseCaseError)
    }
}

// MARK: - Mock Classes

private class MockMovieRepository: MovieRepositoryProtocol {
    
    // MARK: - Mock Results
    var getPopularMoviesResult: Result<[Movie], Error> = .success([])
    var getGenresResult: Result<[Genre], Error> = .success([])
    var searchMoviesResult: Result<[Movie], Error> = .success([])
    var filterAndSortMoviesResult: Result<[Movie], Error> = .success([])
    
    // MARK: - Call Tracking
    var getPopularMoviesCallCount = 0
    var getGenresCallCount = 0
    var searchMoviesCallCount = 0
    var filterAndSortMoviesCallCount = 0
    
    // MARK: - Behavior Control
    var shouldDelayResponse = false
    
    // MARK: - Protocol Implementation
    
    func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error> {
        getPopularMoviesCallCount += 1
        
        return Future<[Movie], Error> { [weak self] promise in
            let completion = {
                guard let self = self else { return }
                switch self.getPopularMoviesResult {
                case .success(let movies):
                    promise(.success(movies))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
            
            if self?.shouldDelayResponse == true {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    completion()
                }
            } else {
                completion()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getGenres() -> AnyPublisher<[Genre], Error> {
        getGenresCallCount += 1
        
        return Future<[Genre], Error> { [weak self] promise in
            let completion = {
                guard let self = self else { return }
                switch self.getGenresResult {
                case .success(let genres):
                    promise(.success(genres))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
            
            if self?.shouldDelayResponse == true {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    completion()
                }
            } else {
                completion()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        searchMoviesCallCount += 1
        
        return Future<[Movie], Error> { [weak self] promise in
            let completion = {
                guard let self = self else { return }
                switch self.searchMoviesResult {
                case .success(let movies):
                    promise(.success(movies))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
            
            if self?.shouldDelayResponse == true {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    completion()
                }
            } else {
                completion()
            }
        }
        .eraseToAnyPublisher()
    }
    
    func filterAndSortMovies(genreIds: [Int], sortOption: MovieSortOption, page: Int) -> AnyPublisher<[Movie], Error> {
        filterAndSortMoviesCallCount += 1
        
        return Future<[Movie], Error> { [weak self] promise in
            let completion = {
                guard let self = self else { return }
                switch self.filterAndSortMoviesResult {
                case .success(let movies):
                    promise(.success(movies))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
            
            if self?.shouldDelayResponse == true {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    completion()
                }
            } else {
                completion()
            }
        }
        .eraseToAnyPublisher()
    }
}
