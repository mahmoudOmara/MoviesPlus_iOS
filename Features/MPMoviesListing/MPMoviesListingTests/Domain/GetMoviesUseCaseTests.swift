//
//  GetMoviesUseCaseTests.swift
//  MPMoviesListing
//
//  Created by mac on 08/08/2025.
//

import XCTest
import Combine
import MPCore
@testable import MPMoviesListing

final class GetMoviesUseCaseTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var useCase: GetMoviesUseCase!
    private var mockRepository: MockMovieRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockMovieRepository()
        useCase = GetMoviesUseCase(repository: mockRepository)
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
        let testUseCase = GetMoviesUseCase(repository: mockRepository)
        
        // Assert
        XCTAssertNotNil(testUseCase)
    }
    
    // MARK: - Input Validation Tests
    
    func test_execute_withValidPage_callsRepository() {
        // Arrange
        let validPage = 1
        let expectedMovies = [Movie.sample]
        mockRepository.getPopularMoviesResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Repository called with valid page")
        
        // Act
        useCase.execute(page: validPage)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { movies in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
        XCTAssertEqual(mockRepository.lastPageRequested, validPage)
    }
    
    func test_execute_withZeroPage_returnsInvalidPageError() {
        // Arrange
        let invalidPage = 0
        let expectation = XCTestExpectation(description: "Invalid page error received")
        
        // Act
        useCase.execute(page: invalidPage)
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
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 0)
    }
    
    func test_execute_withNegativePage_returnsInvalidPageError() {
        // Arrange
        let invalidPage = -1
        let expectation = XCTestExpectation(description: "Invalid page error received")
        
        // Act
        useCase.execute(page: invalidPage)
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
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 0)
    }
    
    func test_execute_withPageOne_isValidAndCallsRepository() {
        // Arrange
        let validPage = 1
        mockRepository.getPopularMoviesResult = .success([])
        
        let expectation = XCTestExpectation(description: "Page 1 is valid")
        
        // Act
        useCase.execute(page: validPage)
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
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
    }
    
    // MARK: - Repository Integration Tests
    
    func test_execute_withSuccessfulRepository_returnsMovies() {
        // Arrange
        let page = 1
        let expectedMovies = [
            Movie(id: 1, title: "Movie 1"),
            Movie(id: 2, title: "Movie 2"),
            Movie(id: 3, title: "Movie 3")
        ]
        mockRepository.getPopularMoviesResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Movies received successfully")
        
        // Act
        useCase.execute(page: page)
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
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
    }
    
    func test_execute_withEmptyRepository_returnsEmptyArray() {
        // Arrange
        let page = 1
        let expectedMovies: [Movie] = []
        mockRepository.getPopularMoviesResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Empty array received")
        
        // Act
        useCase.execute(page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with empty repository result")
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
    
    // MARK: - Error Propagation Tests
    
    func test_execute_withRepositoryNetworkError_propagatesError() {
        // Arrange
        let page = 1
        let repositoryError = RepositoryError.remote(.networkUnavailable)
        mockRepository.getPopularMoviesResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Repository error propagated")
        
        // Act
        useCase.execute(page: page)
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
    
    func test_execute_withRepositoryGenericError_propagatesError() {
        // Arrange
        let page = 1
        let repositoryError = RepositoryError.unknown(NSError(domain: "TestError", code: 500, userInfo: nil))
        mockRepository.getPopularMoviesResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Generic repository error propagated")
        
        // Act
        useCase.execute(page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let repoError = error as? RepositoryError,
                       case .unknown = repoError {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value when repository operation fails")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Edge Case Tests
    
    func test_execute_multipleConcurrentCalls_handlesCorrectly() {
        // Arrange
        let page1 = 1
        let page2 = 2
        let movies1 = [Movie(id: 1, title: "Movie 1")]
        let movies2 = [Movie(id: 2, title: "Movie 2")]
        
        // Set up repository to return different results for different pages
        mockRepository.customPageHandler = { page in
            if page == 1 {
                return .success(movies1)
            } else {
                return .success(movies2)
            }
        }
        
        let expectation1 = XCTestExpectation(description: "First call completed")
        let expectation2 = XCTestExpectation(description: "Second call completed")
        
        // Act - Make concurrent calls
        useCase.execute(page: page1)
            .sink(
                receiveCompletion: { _ in expectation1.fulfill() },
                receiveValue: { movies in
                    XCTAssertEqual(movies, movies1)
                }
            )
            .store(in: &cancellables)
        
        useCase.execute(page: page2)
            .sink(
                receiveCompletion: { _ in expectation2.fulfill() },
                receiveValue: { movies in
                    XCTAssertEqual(movies, movies2)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation1, expectation2], timeout: 2.0)
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 2)
    }
    
    // MARK: - Integration Tests
    
    func test_execute_fullSuccessFlow_worksEndToEnd() {
        // Arrange
        let page = 1
        let expectedMovies = [
            Movie(
                id: 550,
                title: "Fight Club",
                overview: "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.",
                posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
                releaseDate: Date(),
                voteAverage: 8.433,
                genreIds: [18, 53, 35]
            )
        ]
        mockRepository.getPopularMoviesResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Full success flow completed")
        
        // Act
        useCase.execute(page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        // Success completion
                    }
                    expectation.fulfill()
                },
                receiveValue: { movies in
                    // Verify all movie properties
                    XCTAssertEqual(movies.count, 1)
                    let movie = movies.first!
                    let expectedMovie = expectedMovies[0]
                    XCTAssertEqual(movie.id, expectedMovie.id)
                    XCTAssertEqual(movie.title, expectedMovie.title)
                    XCTAssertEqual(movie.overview, expectedMovie.overview)
                    XCTAssertEqual(movie.posterPath, expectedMovie.posterPath)
                    XCTAssertEqual(movie.voteAverage, expectedMovie.voteAverage)
                    XCTAssertEqual(movie.genreIds, expectedMovie.genreIds)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
        XCTAssertEqual(mockRepository.lastPageRequested, page)
    }
    
    // MARK: - Publisher Behavior Tests
    
    func test_execute_returnsPublisherThatCanBeCancelled() {
        // Arrange
        let page = 1
        mockRepository.getPopularMoviesResult = .success([Movie.sample])
        
        // Act
        let cancellable = useCase.execute(page: page)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
        
        // Assert - Publisher can be cancelled without issues
        cancellable.cancel()
        XCTAssertNotNil(cancellable)
    }
    
    func test_execute_publisherCompletesAfterValue() {
        // Arrange
        let page = 1
        let movies = [Movie.sample]
        mockRepository.getPopularMoviesResult = .success(movies)
        
        var completionReceived = false
        var valueReceived = false
        let expectation = XCTestExpectation(description: "Publisher behavior verified")
        
        // Act
        useCase.execute(page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        completionReceived = true
                        if valueReceived {
                            expectation.fulfill()
                        }
                    }
                },
                receiveValue: { _ in
                    valueReceived = true
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(completionReceived)
        XCTAssertTrue(valueReceived)
    }
}

// MARK: - Mock Repository

private class MockMovieRepository: MovieRepositoryProtocol {
    
    // MARK: - Test Properties
    
    var getPopularMoviesCallCount = 0
    var lastPageRequested: Int?
    var getPopularMoviesResult: Result<[Movie], Error> = .success([])
    var customPageHandler: ((Int) -> Result<[Movie], Error>)?
    
    // MARK: - MovieRepositoryProtocol Implementation
    
    func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error> {
        getPopularMoviesCallCount += 1
        lastPageRequested = page
        
        // Use custom handler if provided
        if let customHandler = customPageHandler {
            let result = customHandler(page)
            return result.publisher.eraseToAnyPublisher()
        }
        
        return getPopularMoviesResult.publisher.eraseToAnyPublisher()
    }
    
    func getGenres() -> AnyPublisher<[Genre], Error> {
        return Empty<[Genre], Error>().eraseToAnyPublisher()
    }
    
    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
    
    func filterAndSortMovies(genreIds: [Int], sortOption: MovieSortOption, page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
}
