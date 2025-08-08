//
//  GetGenresUseCaseTests.swift
//  MPMoviesListing
//
//  Created by mac on 08/08/2025.
//

import XCTest
import Combine
import MPCore
@testable import MPMoviesListing

final class GetGenresUseCaseTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var useCase: GetGenresUseCase!
    private var mockRepository: MockGenresRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockGenresRepository()
        useCase = GetGenresUseCase(repository: mockRepository)
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
        let testUseCase = GetGenresUseCase(repository: mockRepository)
        
        // Assert
        XCTAssertNotNil(testUseCase)
    }
    
    // MARK: - Repository Integration Tests
    
    func test_execute_callsRepositoryGetGenres() {
        // Arrange
        let expectedGenres = [Genre.sample]
        mockRepository.getGenresResult = .success(expectedGenres)
        
        let expectation = XCTestExpectation(description: "Repository getGenres called")
        
        // Act
        useCase.execute()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { genres in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getGenresCallCount, 1)
    }
    
    func test_execute_withSuccessfulRepository_returnsGenres() {
        // Arrange
        let expectedGenres = [
            Genre(id: 28, name: "Action"),
            Genre(id: 12, name: "Adventure"),
            Genre(id: 16, name: "Animation"),
            Genre(id: 35, name: "Comedy"),
            Genre(id: 80, name: "Crime"),
            Genre(id: 99, name: "Documentary"),
            Genre(id: 18, name: "Drama"),
            Genre(id: 10751, name: "Family"),
            Genre(id: 14, name: "Fantasy"),
            Genre(id: 36, name: "History"),
            Genre(id: 27, name: "Horror"),
            Genre(id: 10402, name: "Music"),
            Genre(id: 9648, name: "Mystery"),
            Genre(id: 10749, name: "Romance"),
            Genre(id: 878, name: "Science Fiction"),
            Genre(id: 10770, name: "TV Movie"),
            Genre(id: 53, name: "Thriller"),
            Genre(id: 10752, name: "War"),
            Genre(id: 37, name: "Western")
        ]
        mockRepository.getGenresResult = .success(expectedGenres)
        
        let expectation = XCTestExpectation(description: "Genres received successfully")
        
        // Act
        useCase.execute()
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with successful repository")
                    }
                },
                receiveValue: { genres in
                    XCTAssertEqual(genres.count, expectedGenres.count)
                    XCTAssertEqual(genres, expectedGenres)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getGenresCallCount, 1)
    }
    
    func test_execute_withEmptyGenres_returnsEmptyArray() {
        // Arrange
        let emptyGenres: [Genre] = []
        mockRepository.getGenresResult = .success(emptyGenres)
        
        let expectation = XCTestExpectation(description: "Empty genres array received")
        
        // Act
        useCase.execute()
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with empty result")
                    }
                },
                receiveValue: { genres in
                    XCTAssertTrue(genres.isEmpty)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_execute_withSingleGenre_returnsSingleGenre() {
        // Arrange
        let singleGenre = [Genre(id: 28, name: "Action")]
        mockRepository.getGenresResult = .success(singleGenre)
        
        let expectation = XCTestExpectation(description: "Single genre received")
        
        // Act
        useCase.execute()
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with single genre")
                    }
                },
                receiveValue: { genres in
                    XCTAssertEqual(genres.count, 1)
                    XCTAssertEqual(genres.first?.id, singleGenre.first?.id)
                    XCTAssertEqual(genres.first?.name, singleGenre.first?.name)
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
        let repositoryError = RepositoryError.remote(.networkUnavailable)
        mockRepository.getGenresResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Repository error propagated")
        
        // Act
        useCase.execute()
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
        let repositoryError = RepositoryError.unknown(NSError(domain: "TestError", code: 500, userInfo: nil))
        mockRepository.getGenresResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Repository error propagated")
        
        // Act
        useCase.execute()
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
    
    func test_execute_withCustomRepositoryError_propagatesError() {
        // Arrange
        struct CustomError: Error, Equatable {
            let message: String
        }
        let customError = CustomError(message: "Custom repository error")
        mockRepository.getGenresResult = .failure(customError)
        
        let expectation = XCTestExpectation(description: "Custom error propagated")
        
        // Act
        useCase.execute()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let receivedCustomError = error as? CustomError,
                       receivedCustomError == customError {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value when repository fails with custom error")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Publisher Behavior Tests
    
    func test_execute_returnsPublisherThatCanBeCancelled() {
        // Arrange
        mockRepository.getGenresResult = .success([Genre.sample])
        
        // Act
        let cancellable = useCase.execute()
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
        let genres = [Genre.sample]
        mockRepository.getGenresResult = .success(genres)
        
        var completionReceived = false
        var valueReceived = false
        let expectation = XCTestExpectation(description: "Publisher behavior verified")
        
        // Act
        useCase.execute()
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
    
    // MARK: - Multiple Calls Tests
    
    func test_execute_multipleCalls_eachCallsRepository() {
        // Arrange
        mockRepository.getGenresResult = .success([Genre.sample])
        
        let expectation1 = XCTestExpectation(description: "First call completed")
        let expectation2 = XCTestExpectation(description: "Second call completed")
        
        // Act - Multiple calls
        useCase.execute()
            .sink(
                receiveCompletion: { _ in expectation1.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        useCase.execute()
            .sink(
                receiveCompletion: { _ in expectation2.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation1, expectation2], timeout: 2.0)
        XCTAssertEqual(mockRepository.getGenresCallCount, 2)
    }
    
    func test_execute_concurrentCalls_handledCorrectly() {
        // Arrange
        let genres1 = [Genre(id: 28, name: "Action")]
        let genres2 = [Genre(id: 12, name: "Adventure")]
        
        var callCount = 0
        mockRepository.customGenresHandler = {
            callCount += 1
            return callCount == 1 ? .success(genres1) : .success(genres2)
        }
        
        let expectation1 = XCTestExpectation(description: "First concurrent call completed")
        let expectation2 = XCTestExpectation(description: "Second concurrent call completed")
        
        // Act - Concurrent calls
        useCase.execute()
            .sink(
                receiveCompletion: { _ in expectation1.fulfill() },
                receiveValue: { genres in
                    // Either result is acceptable due to concurrent nature
                    XCTAssertFalse(genres.isEmpty)
                }
            )
            .store(in: &cancellables)
        
        useCase.execute()
            .sink(
                receiveCompletion: { _ in expectation2.fulfill() },
                receiveValue: { genres in
                    // Either result is acceptable due to concurrent nature
                    XCTAssertFalse(genres.isEmpty)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation1, expectation2], timeout: 2.0)
        XCTAssertEqual(mockRepository.getGenresCallCount, 2)
    }
    
    // MARK: - Integration Tests
    
    func test_execute_fullSuccessFlow_worksEndToEnd() {
        // Arrange
        let expectedGenres = [
            Genre(id: 28, name: "Action"),
            Genre(id: 12, name: "Adventure"),
            Genre(id: 35, name: "Comedy"),
            Genre(id: 18, name: "Drama"),
            Genre(id: 27, name: "Horror"),
            Genre(id: 10749, name: "Romance"),
            Genre(id: 878, name: "Science Fiction"),
            Genre(id: 53, name: "Thriller")
        ]
        mockRepository.getGenresResult = .success(expectedGenres)
        
        let expectation = XCTestExpectation(description: "Full success flow completed")
        
        // Act
        useCase.execute()
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        // Success completion
                    }
                    expectation.fulfill()
                },
                receiveValue: { genres in
                    // Verify all genres are correct
                    XCTAssertEqual(genres.count, expectedGenres.count)
                    XCTAssertEqual(genres, expectedGenres)
                    
                    // Verify specific genres
                    XCTAssertTrue(genres.contains { $0.id == 28 && $0.name == "Action" })
                    XCTAssertTrue(genres.contains { $0.id == 878 && $0.name == "Science Fiction" })
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getGenresCallCount, 1)
    }
}

// MARK: - Mock Repository

private class MockGenresRepository: MovieRepositoryProtocol {
    
    // MARK: - Test Properties
    
    var getGenresCallCount = 0
    var getGenresResult: Result<[Genre], Error> = .success([])
    var customGenresHandler: (() -> Result<[Genre], Error>)?
    
    // MARK: - MovieRepositoryProtocol Implementation
    
    func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
    
    func getGenres() -> AnyPublisher<[Genre], Error> {
        getGenresCallCount += 1
        
        // Use custom handler if provided
        if let customHandler = customGenresHandler {
            let result = customHandler()
            return result.publisher.eraseToAnyPublisher()
        }
        
        return getGenresResult.publisher.eraseToAnyPublisher()
    }
    
    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
    
    func filterAndSortMovies(genreIds: [Int], sortOption: MovieSortOption, page: Int) -> AnyPublisher<[Movie], Error> {
        return Empty<[Movie], Error>().eraseToAnyPublisher()
    }
}
