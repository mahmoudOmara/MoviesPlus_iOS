//
//  SearchMoviesUseCaseTests.swift
//  MPMoviesListing
//
//  Created by mac on 08/08/2025.
//

import Combine
import MPCore
@testable import MPMoviesListing
import XCTest

final class SearchMoviesUseCaseTests: XCTestCase {
    // MARK: - Test Properties
    
    private var useCase: SearchMoviesUseCase!
    private var mockRepository: MockSearchRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockSearchRepository()
        useCase = SearchMoviesUseCase(repository: mockRepository) // Default minimum length = 2
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_withDefaultMinimumQueryLength_setsCorrectly() {
        // Assert - Test by trying a query of length 1 (should fail)
        let expectation = XCTestExpectation(description: "Default minimum length is 2")
        
        useCase.execute(query: "a", page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case let .tooShortSearchQuery(minimumLength) = useCaseError {
                        XCTAssertEqual(minimumLength, 2)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for too short query")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_init_withCustomMinimumQueryLength_setsCorrectly() {
        // Arrange
        let customMinLength = 5
        let testUseCase = SearchMoviesUseCase(repository: mockRepository, minimumQueryLength: customMinLength)
        
        let expectation = XCTestExpectation(description: "Custom minimum length set")
        
        // Act - Try a query shorter than custom minimum
        testUseCase.execute(query: "test", page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case let .tooShortSearchQuery(minimumLength) = useCaseError {
                        XCTAssertEqual(minimumLength, customMinLength)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for too short query")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Query Validation Tests
    
    func test_execute_withValidQuery_callsRepository() {
        // Arrange
        let validQuery = "batman"
        let page = 1
        let expectedMovies = [Movie.sample]
        mockRepository.searchResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Repository called with valid query")
        
        // Act
        useCase.execute(query: validQuery, page: page)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.searchCallCount, 1)
        XCTAssertEqual(mockRepository.lastQueryRequested, validQuery)
    }
    
    func test_execute_withEmptyQuery_returnsError() {
        // Arrange
        let emptyQuery = ""
        let page = 1
        let expectation = XCTestExpectation(description: "Empty query error received")
        
        // Act
        useCase.execute(query: emptyQuery, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case let .tooShortSearchQuery(minimumLength) = useCaseError {
                        XCTAssertEqual(minimumLength, 2)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for empty query")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.searchCallCount, 0)
    }
    
    func test_execute_withMinimumLengthQuery_callsRepository() {
        // Arrange - Default minimum is 2
        let minimumQuery = "ab"
        let page = 1
        mockRepository.searchResult = .success([])
        
        let expectation = XCTestExpectation(description: "Minimum length query accepted")
        
        // Act
        useCase.execute(query: minimumQuery, page: page)
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
        XCTAssertEqual(mockRepository.searchCallCount, 1)
    }
    
    // MARK: - Whitespace Handling Tests
    
    func test_execute_withLeadingWhitespace_trimsAndCallsRepository() {
        // Arrange
        let queryWithWhitespace = "   batman"
        let expectedTrimmedQuery = "batman"
        let page = 1
        mockRepository.searchResult = .success([])
        
        let expectation = XCTestExpectation(description: "Leading whitespace trimmed")
        
        // Act
        useCase.execute(query: queryWithWhitespace, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastQueryRequested, expectedTrimmedQuery)
    }
    
    func test_execute_withTrailingWhitespace_trimsAndCallsRepository() {
        // Arrange
        let queryWithWhitespace = "superman   "
        let expectedTrimmedQuery = "superman"
        let page = 1
        mockRepository.searchResult = .success([])
        
        let expectation = XCTestExpectation(description: "Trailing whitespace trimmed")
        
        // Act
        useCase.execute(query: queryWithWhitespace, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastQueryRequested, expectedTrimmedQuery)
    }
    
    func test_execute_withNewlinesAndTabs_trimsAndCallsRepository() {
        // Arrange
        let queryWithWhitespace = "\n\t  wonder woman  \t\n"
        let expectedTrimmedQuery = "wonder woman"
        let page = 1
        mockRepository.searchResult = .success([])
        
        let expectation = XCTestExpectation(description: "Newlines and tabs trimmed")
        
        // Act
        useCase.execute(query: queryWithWhitespace, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastQueryRequested, expectedTrimmedQuery)
    }
    
    func test_execute_withWhitespaceMakingQueryTooShort_returnsError() {
        // Arrange - Query becomes too short after trimming
        let query = " a " // After trimming: "a" (length 1, below minimum of 2)
        let page = 1
        let expectation = XCTestExpectation(description: "Query too short after trimming")
        
        // Act
        useCase.execute(query: query, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case .tooShortSearchQuery = useCaseError {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for query too short after trimming")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.searchCallCount, 0)
    }
    
    // MARK: - Repository Integration Tests
    
    func test_execute_withSuccessfulRepository_returnsMovies() {
        // Arrange
        let query = "action"
        let page = 1
        let expectedMovies = [
            Movie(id: 1, title: "Action Movie 1"),
            Movie(id: 2, title: "Another Action Film"),
            Movie(id: 3, title: "Action Adventure"),
        ]
        mockRepository.searchResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Search results received")
        
        // Act
        useCase.execute(query: query, page: page)
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
        XCTAssertEqual(mockRepository.searchCallCount, 1)
    }
    
    func test_execute_withEmptyResult_returnsEmptyArray() {
        // Arrange
        let query = "nonexistent movie"
        let page = 1
        mockRepository.searchResult = .success([])
        
        let expectation = XCTestExpectation(description: "Empty search result received")
        
        // Act
        useCase.execute(query: query, page: page)
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
    
    func test_execute_passesCorrectParametersToRepository() {
        // Arrange
        let testQuery = "marvel movies"
        let testPage = 5
        mockRepository.searchResult = .success([])
        
        let expectation = XCTestExpectation(description: "Parameters passed correctly")
        
        // Act
        useCase.execute(query: testQuery, page: testPage)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastQueryRequested, testQuery)
        XCTAssertEqual(mockRepository.lastPageRequested, testPage)
    }
    
    // MARK: - Error Propagation Tests
    
    func test_execute_withRepositoryNetworkError_propagatesError() {
        // Arrange
        let query = "batman"
        let page = 1
        let repositoryError = RepositoryError.remote(.networkUnavailable)
        mockRepository.searchResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Repository error propagated")
        
        // Act
        useCase.execute(query: query, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion,
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
        let query = "superman"
        let page = 1
        let repositoryError = RepositoryError.unknown(NSError(domain: "TestError", code: 500, userInfo: nil))
        mockRepository.searchResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Repository error propagated")
        
        // Act
        useCase.execute(query: query, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion,
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
    
    func test_execute_withEmojies_handlesCorrectly() {
        // Arrange
        let emojie = "🦸‍♂️ héro"
        let page = 1
        mockRepository.searchResult = .success([])
        
        let expectation = XCTestExpectation(description: "Unicode characters handled")
        
        // Act
        useCase.execute(query: emojie, page: page)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastQueryRequested, emojie)
    }
    
    func test_execute_multipleConcurrentSearches_handlesCorrectly() {
        // Arrange
        let query1 = "batman"
        let query2 = "superman"
        let page1 = 1
        let page2 = 2
        
        let movies1 = [Movie(id: 1, title: "Batman")]
        let movies2 = [Movie(id: 2, title: "Superman")]
        
        mockRepository.customSearchHandler = { query, _ in
            if query == query1 {
                return .success(movies1)
            } else {
                return .success(movies2)
            }
        }
        
        let expectation1 = XCTestExpectation(description: "First search completed")
        let expectation2 = XCTestExpectation(description: "Second search completed")
        
        // Act - Concurrent searches
        useCase.execute(query: query1, page: page1)
            .sink(
                receiveCompletion: { _ in expectation1.fulfill() },
                receiveValue: { movies in
                    XCTAssertEqual(movies, movies1)
                }
            )
            .store(in: &cancellables)
        
        useCase.execute(query: query2, page: page2)
            .sink(
                receiveCompletion: { _ in expectation2.fulfill() },
                receiveValue: { movies in
                    XCTAssertEqual(movies, movies2)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation1, expectation2], timeout: 2.0)
        XCTAssertEqual(mockRepository.searchCallCount, 2)
    }
    
    // MARK: - Custom Minimum Length Tests
    
    func test_execute_withCustomMinimumLength_enforcesCorrectly() {
        // Arrange
        let customMinLength = 3
        let customUseCase = SearchMoviesUseCase(repository: mockRepository, minimumQueryLength: customMinLength)
        
        let validQuery = "abc" // Exactly minimum length
        let invalidQuery = "ab" // Below minimum length
        mockRepository.searchResult = .success([])
        
        let validExpectation = XCTestExpectation(description: "Valid query accepted")
        let invalidExpectation = XCTestExpectation(description: "Invalid query rejected")
        
        // Act - Test valid query
        customUseCase.execute(query: validQuery, page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        validExpectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Act - Test invalid query
        customUseCase.execute(query: invalidQuery, page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case let .tooShortSearchQuery(minimumLength) = useCaseError {
                        XCTAssertEqual(minimumLength, customMinLength)
                        invalidExpectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for invalid query")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [validExpectation, invalidExpectation], timeout: 2.0)
    }
    
    // MARK: - Integration Tests
    
    func test_execute_fullSuccessFlow_worksEndToEnd() {
        // Arrange
        let searchQuery = "Marvel Avengers"
        let expectedTrimmedQuery = "Marvel Avengers"
        let page = 1
        let expectedMovies = [
            Movie(
                id: 299536,
                title: "Avengers: Infinity War",
                overview: "The Avengers must stop Thanos...",
                voteAverage: 8.3
            ),
            Movie(
                id: 299534,
                title: "Avengers: Endgame",
                overview: "The grave course of events...",
                voteAverage: 8.4
            ),
        ]
        mockRepository.searchResult = .success(expectedMovies)
        
        let expectation = XCTestExpectation(description: "Full search flow completed")
        
        // Act
        useCase.execute(query: searchQuery, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        // Success completion
                    }
                    expectation.fulfill()
                },
                receiveValue: { movies in
                    // Verify all search results
                    XCTAssertEqual(movies.count, 2)
                    XCTAssertEqual(movies, expectedMovies)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.searchCallCount, 1)
        XCTAssertEqual(mockRepository.lastQueryRequested, expectedTrimmedQuery)
        XCTAssertEqual(mockRepository.lastPageRequested, page)
    }
}

// MARK: - Mock Repository

private class MockSearchRepository: MovieRepositoryProtocol {
    // MARK: - Test Properties
    
    var searchCallCount = 0
    var lastQueryRequested: String?
    var lastPageRequested: Int?
    var searchResult: Result<[Movie], Error> = .success([])
    var customSearchHandler: ((String, Int) -> Result<[Movie], Error>)?
    
    // MARK: - MovieRepositoryProtocol Implementation
    
    func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
    
    func getGenres() -> AnyPublisher<[Genre], Error> {
        return Empty<[Genre], Error>().eraseToAnyPublisher()
    }
    
    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        searchCallCount += 1
        lastQueryRequested = query
        lastPageRequested = page
        
        // Use custom handler if provided
        if let customHandler = customSearchHandler {
            let result = customHandler(query, page)
            return result.publisher.eraseToAnyPublisher()
        }
        
        return searchResult.publisher.eraseToAnyPublisher()
    }
    
    func filterAndSortMovies(genreIds: [Int], sortOption: MovieSortOption, page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
}
