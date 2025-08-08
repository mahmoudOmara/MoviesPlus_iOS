//
//  FilterAndSortMoviesUseCaseTests.swift
//  MPMoviesListing
//
//  Created by mac on 08/08/2025.
//

import XCTest
import Combine
import MPCore
@testable import MPMoviesListing

final class FilterAndSortMoviesUseCaseTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var useCase: FilterAndSortMoviesUseCase!
    private var mockRepository: MockFilterAndSortRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockFilterAndSortRepository()
        useCase = FilterAndSortMoviesUseCase(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_withRepository_setsRepositoryCorrectly() {
        // Arrange & Act
        let testUseCase = FilterAndSortMoviesUseCase(repository: mockRepository)
        
        // Assert
        XCTAssertNotNil(testUseCase)
    }
    
    // MARK: - Input Validation Tests - Page Number
    
    func test_execute_withValidPage_callsRepository() {
        // Arrange
        let genreIds = [28, 12]
        let sortOption = MovieSortOption.popularity
        let validPage = 1
        let expectedMovies = [Movie.sample]
        mockRepository.filterAndSortResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Repository called with valid page")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: validPage)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { movies in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 1)
        XCTAssertEqual(mockRepository.lastPageRequested, validPage)
    }
    
    func test_execute_withZeroPage_returnsInvalidPageError() {
        // Arrange
        let genreIds = [28]
        let sortOption = MovieSortOption.rating
        let invalidPage = 0
        let expectation = XCTestExpectation(description: "Invalid page error received")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: invalidPage)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case .invalidPage = useCaseError {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for invalid page")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 0)
    }
    
    func test_execute_withNegativePage_returnsInvalidPageError() {
        // Arrange
        let genreIds = [12, 16]
        let sortOption = MovieSortOption.title
        let invalidPage = -5
        let expectation = XCTestExpectation(description: "Invalid page error received")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: invalidPage)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case .invalidPage = useCaseError {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for negative page")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 0)
    }
    
    // MARK: - Genre IDs Input Tests
    
    func test_execute_withEmptyGenreIds_passesToRepository() {
        // Arrange
        let emptyGenreIds: [Int] = []
        let sortOption = MovieSortOption.popularity
        let page = 1
        mockRepository.filterAndSortResult = .success([])
        
        let expectation = XCTestExpectation(description: "Empty genre IDs handled correctly")
        
        // Act
        useCase.execute(genreIds: emptyGenreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 1)
        XCTAssertEqual(mockRepository.lastGenreIdsRequested, emptyGenreIds)
    }
    
    func test_execute_withSingleGenreId_passesToRepository() {
        // Arrange
        let singleGenreId = [28]
        let sortOption = MovieSortOption.rating
        let page = 1
        mockRepository.filterAndSortResult = .success([Movie.sample])
        
        let expectation = XCTestExpectation(description: "Single genre ID handled correctly")
        
        // Act
        useCase.execute(genreIds: singleGenreId, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 1)
        XCTAssertEqual(mockRepository.lastGenreIdsRequested, singleGenreId)
    }
    
    func test_execute_withMultipleGenreIds_passesToRepository() {
        // Arrange
        let multipleGenreIds = [28, 12, 16, 35]
        let sortOption = MovieSortOption.releaseDate
        let page = 2
        mockRepository.filterAndSortResult = .success([])
        
        let expectation = XCTestExpectation(description: "Multiple genre IDs handled correctly")
        
        // Act
        useCase.execute(genreIds: multipleGenreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 1)
        XCTAssertEqual(mockRepository.lastGenreIdsRequested, multipleGenreIds)
    }
    
    // MARK: - Sort Option Tests
    
    func test_execute_withPopularitySortOption_passesToRepository() {
        // Arrange
        let genreIds = [28]
        let sortOption = MovieSortOption.popularity
        let page = 1
        mockRepository.filterAndSortResult = .success([])
        
        let expectation = XCTestExpectation(description: "Popularity sort option passed")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastSortOptionRequested, sortOption)
    }
    
    func test_execute_withRatingSortOption_passesToRepository() {
        // Arrange
        let genreIds = [12, 16]
        let sortOption = MovieSortOption.rating
        let page = 1
        mockRepository.filterAndSortResult = .success([])
        
        let expectation = XCTestExpectation(description: "Rating sort option passed")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastSortOptionRequested, sortOption)
    }
    
    func test_execute_withReleaseDateSortOption_passesToRepository() {
        // Arrange
        let genreIds: [Int] = []
        let sortOption = MovieSortOption.releaseDate
        let page = 1
        mockRepository.filterAndSortResult = .success([])
        
        let expectation = XCTestExpectation(description: "Release date sort option passed")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastSortOptionRequested, sortOption)
    }
    
    func test_execute_withTitleSortOption_passesToRepository() {
        // Arrange
        let genreIds = [35, 18] // Comedy, Drama
        let sortOption = MovieSortOption.title
        let page = 3
        mockRepository.filterAndSortResult = .success([])
        
        let expectation = XCTestExpectation(description: "Title sort option passed")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastSortOptionRequested, sortOption)
    }
    
    // MARK: - Repository Integration Tests
    
    func test_execute_withSuccessfulRepository_returnsFilteredMovies() {
        // Arrange
        let genreIds = [28, 12]
        let sortOption = MovieSortOption.rating
        let page = 1
        let expectedMovies = [
            Movie(id: 1, title: "Action Movie", genreIds: [28]),
            Movie(id: 2, title: "Adventure Movie", genreIds: [12]),
            Movie(id: 3, title: "Action Adventure", genreIds: [28, 12])
        ]
        mockRepository.filterAndSortResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Filtered movies received")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with successful repository")
                    }
                },
                receiveValue: { movies in
                    XCTAssertEqual(movies.count, expectedMovies.count)
                    XCTAssertEqual(movies, expectedMovies)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 1)
    }
    
    func test_execute_withEmptyResult_returnsEmptyArray() {
        // Arrange
        let genreIds = [999] // Non-existent genre
        let sortOption = MovieSortOption.popularity
        let page = 1
        mockRepository.filterAndSortResult = .success([])
        
        let expectation = XCTestExpectation(description: "Empty result handled correctly")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with empty result")
                    }
                },
                receiveValue: { movies in
                    XCTAssertTrue(movies.isEmpty)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Parameter Passing Tests
    
    func test_execute_passesAllParametersCorrectly() {
        // Arrange
        let testGenreIds = [28, 12, 16]
        let testSortOption = MovieSortOption.releaseDate
        let testPage = 5
        mockRepository.filterAndSortResult = .success([])
        
        let expectation = XCTestExpectation(description: "All parameters passed correctly")
        
        // Act
        useCase.execute(genreIds: testGenreIds, sortOption: testSortOption, page: testPage)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastGenreIdsRequested, testGenreIds)
        XCTAssertEqual(mockRepository.lastSortOptionRequested, testSortOption)
        XCTAssertEqual(mockRepository.lastPageRequested, testPage)
    }
    
    // MARK: - Error Propagation Tests
    
    func test_execute_withRepositoryNetworkError_propagatesError() {
        // Arrange
        let genreIds = [28]
        let sortOption = MovieSortOption.popularity
        let page = 1
        let repositoryError = RepositoryError.remote(.networkUnavailable)
        mockRepository.filterAndSortResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Repository error propagated")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let repositoryError = error as? RepositoryError,
                       case .remote(.networkUnavailable) = repositoryError {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value when repository fails")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_execute_withRepositoryError_propagatesError() {
        // Arrange
        let genreIds = [12, 16]
        let sortOption = MovieSortOption.rating
        let page = 1
        let repositoryError = RepositoryError.unknown(NSError(domain: "TestError", code: 500, userInfo: nil))
        mockRepository.filterAndSortResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Repository error propagated")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let repoError = error as? RepositoryError,
                       case .unknown = repoError {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value when repository fails")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Edge Case Tests
    
    func test_execute_multipleConcurrentCalls_handlesCorrectly() {
        // Arrange
        let genreIds1 = [28]
        let genreIds2 = [12, 16]
        let sortOption1 = MovieSortOption.popularity
        let sortOption2 = MovieSortOption.rating
        let page1 = 1
        let page2 = 2
        
        let movies1 = [Movie(id: 1, title: "Movie 1")]
        let movies2 = [Movie(id: 2, title: "Movie 2")]
        
        mockRepository.customHandler = { genreIds, sortOption, page in
            if page == 1 {
                return .success(movies1)
            } else {
                return .success(movies2)
            }
        }
        
        let expectation1 = XCTestExpectation(description: "First call completed")
        let expectation2 = XCTestExpectation(description: "Second call completed")
        
        // Act - Concurrent calls
        useCase.execute(genreIds: genreIds1, sortOption: sortOption1, page: page1)
            .sink(
                receiveCompletion: { _ in expectation1.fulfill() },
                receiveValue: { movies in
                    XCTAssertEqual(movies, movies1)
                }
            )
            .store(in: &cancellables)
        
        useCase.execute(genreIds: genreIds2, sortOption: sortOption2, page: page2)
            .sink(
                receiveCompletion: { _ in expectation2.fulfill() },
                receiveValue: { movies in
                    XCTAssertEqual(movies, movies2)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation1, expectation2], timeout: 2.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 2)
    }
    
    // MARK: - Integration Tests
    
    func test_execute_fullSuccessFlow_worksEndToEnd() {
        // Arrange
        let genreIds = [28, 12] // Action, Adventure
        let sortOption = MovieSortOption.rating
        let page = 1
        let expectedMovies = [
            Movie(
                id: 550,
                title: "Fight Club",
                overview: "A ticking-time-bomb insomniac...",
                voteAverage: 8.433,
                genreIds: [18, 53]
            ),
            Movie(
                id: 680,
                title: "Pulp Fiction",
                overview: "A burger-loving hit man...",
                voteAverage: 8.9,
                genreIds: [80, 18]
            )
        ]
        mockRepository.filterAndSortResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Full success flow completed")
        
        // Act
        useCase.execute(genreIds: genreIds, sortOption: sortOption, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        // Success completion
                    }
                    expectation.fulfill()
                },
                receiveValue: { movies in
                    // Verify all parameters and results
                    XCTAssertEqual(movies.count, 2)
                    XCTAssertEqual(movies, expectedMovies)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.filterAndSortCallCount, 1)
        XCTAssertEqual(mockRepository.lastGenreIdsRequested, genreIds)
        XCTAssertEqual(mockRepository.lastSortOptionRequested, sortOption)
        XCTAssertEqual(mockRepository.lastPageRequested, page)
    }
}

// MARK: - Mock Repository

private class MockFilterAndSortRepository: MovieRepositoryProtocol {
    
    // MARK: - Test Properties
    
    var filterAndSortCallCount = 0
    var lastGenreIdsRequested: [Int]?
    var lastSortOptionRequested: MovieSortOption?
    var lastPageRequested: Int?
    var filterAndSortResult: Result<[Movie], Error> = .success([])
    var customHandler: (([Int], MovieSortOption, Int) -> Result<[Movie], Error>)?
    
    // MARK: - MovieRepositoryProtocol Implementation
    
    func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
    
    func getGenres() -> AnyPublisher<[Genre], Error> {
        return Empty<[Genre], Error>().eraseToAnyPublisher()
    }
    
    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
    
    func filterAndSortMovies(genreIds: [Int], sortOption: MovieSortOption, page: Int) -> AnyPublisher<[Movie], Error> {
        filterAndSortCallCount += 1
        lastGenreIdsRequested = genreIds
        lastSortOptionRequested = sortOption
        lastPageRequested = page
        
        // Use custom handler if provided
        if let customHandler = customHandler {
            let result = customHandler(genreIds, sortOption, page)
            return result.publisher.eraseToAnyPublisher()
        }
        
        return filterAndSortResult.publisher.eraseToAnyPublisher()
    }
}
