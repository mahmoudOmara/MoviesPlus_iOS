//
//  GetMovieDetailsUseCaseTests.swift
//  MPMovieDetails
//
//  Created by mac on 08/08/2025.
//

import XCTest
import Combine
import MPCore
@testable import MPMovieDetails

final class GetMovieDetailsUseCaseTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var useCase: GetMovieDetailsUseCase!
    private var mockRepository: MockMovieDetailsRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockMovieDetailsRepository()
        useCase = GetMovieDetailsUseCase(repository: mockRepository)
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
        let testUseCase = GetMovieDetailsUseCase(repository: mockRepository)
        
        // Assert
        XCTAssertNotNil(testUseCase)
    }
    
    // MARK: - Input Validation Tests
    
    func test_execute_withValidMovieId_callsRepository() {
        // Arrange
        let movieId = 123
        let expectedMovieDetails = MovieDetails.sampleFightClub
        mockRepository.getMovieDetailsResult = .success(expectedMovieDetails)
        
        let expectation = XCTestExpectation(description: "Repository called with valid movie ID")
        
        // Act
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with valid movie ID")
                    }
                    expectation.fulfill()
                },
                receiveValue: { movieDetails in
                    XCTAssertEqual(movieDetails.id, expectedMovieDetails.id)
                    XCTAssertTrue(self.mockRepository.getMovieDetailsCalled)
                    XCTAssertEqual(self.mockRepository.lastMovieId, movieId)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_execute_withZeroMovieId_returnsInvalidMovieIdError() {
        // Arrange
        let movieId = 0
        let expectation = XCTestExpectation(description: "Invalid movie ID error returned")
        
        // Act
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case .invalidMovieId = useCaseError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Should return invalidMovieId error for zero movie ID")
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value with invalid movie ID")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(mockRepository.getMovieDetailsCalled, "Repository should not be called with invalid movie ID")
    }
    
    func test_execute_withNegativeMovieId_returnsInvalidMovieIdError() {
        // Arrange
        let movieId = -5
        let expectation = XCTestExpectation(description: "Invalid movie ID error returned for negative ID")
        
        // Act
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case .invalidMovieId = useCaseError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Should return invalidMovieId error for negative movie ID")
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value with negative movie ID")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(mockRepository.getMovieDetailsCalled, "Repository should not be called with negative movie ID")
    }
    
    // MARK: - Repository Integration Tests
    
    func test_execute_withValidMovieId_returnsMovieDetails() {
        // Arrange
        let movieId = 550
        let expectedMovieDetails = MovieDetails.sampleFightClub
        mockRepository.getMovieDetailsResult = .success(expectedMovieDetails)
        
        let expectation = XCTestExpectation(description: "Movie details returned successfully")
        
        // Act
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with valid repository response")
                    }
                },
                receiveValue: { movieDetails in
                    XCTAssertEqual(movieDetails.id, expectedMovieDetails.id)
                    XCTAssertEqual(movieDetails.title, expectedMovieDetails.title)
                    XCTAssertEqual(movieDetails.overview, expectedMovieDetails.overview)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_execute_withRepositoryReturningNil_returnsNoDataError() {
        // Arrange
        let movieId = 123
        mockRepository.getMovieDetailsResult = .success(nil)
        
        let expectation = XCTestExpectation(description: "No data error returned when repository returns nil")
        
        // Act
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let useCaseError = error as? UseCaseError,
                       case .noData = useCaseError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Should return noData error when repository returns nil")
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value when repository returns nil")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Propagation Tests
    
    func test_execute_withRepositoryNetworkError_propagatesError() {
        // Arrange
        let movieId = 123
        let repositoryError = RepositoryError.remote(.networkUnavailable)
        mockRepository.getMovieDetailsResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Repository error propagated")
        
        // Act
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let repoError = error as? RepositoryError,
                       case .remote(.networkUnavailable) = repoError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Should propagate repository network error")
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
    
    func test_execute_withRepositoryLocalError_propagatesError() {
        // Arrange
        let movieId = 123
        let repositoryError = RepositoryError.local(.operationFailed)
        mockRepository.getMovieDetailsResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Local repository error propagated")
        
        // Act
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let repoError = error as? RepositoryError,
                       case .local(.operationFailed) = repoError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Should propagate repository local error")
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
    
    func test_execute_withRepositoryUnknownError_propagatesError() {
        // Arrange
        let movieId = 123
        let genericError = NSError(domain: "TestError", code: 500, userInfo: nil)
        let repositoryError = RepositoryError.unknown(genericError)
        mockRepository.getMovieDetailsResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Unknown repository error propagated")
        
        // Act
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       let repoError = error as? RepositoryError,
                       case .unknown = repoError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Should propagate unknown repository error")
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
        let movieId1 = 123
        let movieId2 = 456
        let movieDetails1 = MovieDetails.sampleFightClub
        let movieDetails2 = MovieDetails.sampleInception
        
        // Set up repository to return different results for different movie IDs
        mockRepository.customMovieHandler = { movieId in
            if movieId == movieId1 {
                return .success(movieDetails1)
            } else {
                return .success(movieDetails2)
            }
        }
        
        let expectation1 = XCTestExpectation(description: "First call completed")
        let expectation2 = XCTestExpectation(description: "Second call completed")
        
        // Act - Make concurrent calls
        useCase.execute(movieId: movieId1)
            .sink(
                receiveCompletion: { _ in expectation1.fulfill() },
                receiveValue: { movieDetails in
                    XCTAssertEqual(movieDetails.id, movieDetails1.id)
                    XCTAssertEqual(movieDetails.title, movieDetails1.title)
                }
            )
            .store(in: &cancellables)
        
        useCase.execute(movieId: movieId2)
            .sink(
                receiveCompletion: { _ in expectation2.fulfill() },
                receiveValue: { movieDetails in
                    XCTAssertEqual(movieDetails.id, movieDetails2.id)
                    XCTAssertEqual(movieDetails.title, movieDetails2.title)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation1, expectation2], timeout: 2.0)
    }
    
    func test_execute_afterRepositoryErrorThenSuccess_handlesCorrectly() {
        // Arrange
        let movieId = 123
        let expectedMovieDetails = MovieDetails.sampleFightClub
        let repositoryError = RepositoryError.remote(.networkUnavailable)
        
        let expectation1 = XCTestExpectation(description: "First call with error completed")
        let expectation2 = XCTestExpectation(description: "Second call with success completed")
        
        // Act - First call fails
        mockRepository.getMovieDetailsResult = .failure(repositoryError)
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        expectation1.fulfill()
                    } else {
                        XCTFail("First call should fail")
                    }
                },
                receiveValue: { _ in
                    XCTFail("First call should not receive value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation1], timeout: 1.0)
        
        // Second call succeeds
        mockRepository.getMovieDetailsResult = .success(expectedMovieDetails)
        useCase.execute(movieId: movieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Second call should succeed")
                    }
                    expectation2.fulfill()
                },
                receiveValue: { movieDetails in
                    XCTAssertEqual(movieDetails.id, expectedMovieDetails.id)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation2], timeout: 1.0)
    }
}

// MARK: - Mock Repository

class MockMovieDetailsRepository: MovieDetailsRepositoryProtocol {
    
    // MARK: - Mock Properties
    
    var getMovieDetailsCalled = false
    var lastMovieId: Int?
    var getMovieDetailsResult: Result<MovieDetails?, Error> = .success(nil)
    var customMovieHandler: ((Int) -> Result<MovieDetails?, Error>)?
    
    // MARK: - Repository Protocol Implementation
    
    func getMovieDetails(movieId: Int) -> AnyPublisher<MovieDetails?, Error> {
        getMovieDetailsCalled = true
        lastMovieId = movieId
        
        // Use custom handler if available
        if let customHandler = customMovieHandler {
            let result = customHandler(movieId)
            switch result {
            case .success(let movieDetails):
                return Just(movieDetails)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            case .failure(let error):
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
        }
        
        // Use default result
        switch getMovieDetailsResult {
        case .success(let movieDetails):
            return Just(movieDetails)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    func reset() {
        getMovieDetailsCalled = false
        lastMovieId = nil
        getMovieDetailsResult = .success(nil)
        customMovieHandler = nil
    }
}

// MARK: - Sample Data Extensions

extension MovieDetails {
    
    /// Sample Fight Club movie details for testing
    static let sampleFightClub = MovieDetails(
        id: 550,
        title: "Fight Club",
        overview: "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.",
        posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
        backdropPath: "/fCayJrkfRaCRCTh8GqN30f8oyQF.jpg",
        releaseDate: Calendar.current.date(from: DateComponents(year: 1999, month: 10, day: 15)),
        voteAverage: 8.4,
        voteCount: 26280,
        originalLanguage: "en",
        budget: 63000000,
        revenue: 100853753,
        runtime: 139,
        status: .released,
        tagline: "Mischief. Mayhem. Soap.",
        genres: [
            Genre(id: 18, name: "Drama"),
            Genre(id: 53, name: "Thriller")
        ],
        productionCompanies: [
            ProductionCompany(id: 508, name: "20th Century Fox", logoPath: "/7PzJdsLGlR7oW4J0J5Xcd0pHGRg.png")
        ]
    )
    
    /// Sample Inception movie details for testing
    static let sampleInception = MovieDetails(
        id: 27205,
        title: "Inception",
        overview: "Cobb, a skilled thief who commits corporate espionage by infiltrating the subconscious of his targets is offered a chance to regain his old life as payment for a task considered to be impossible: \"inception\", the implantation of another person's idea into a target's subconscious.",
        posterPath: "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
        backdropPath: "/aej3LRUga5rhgkmRP6XMFw3ejbl.jpg",
        releaseDate: Calendar.current.date(from: DateComponents(year: 2010, month: 7, day: 16)),
        voteAverage: 8.3,
        voteCount: 34830,
        originalLanguage: "en",
        budget: 160000000,
        revenue: 836836967,
        runtime: 148,
        status: .released,
        tagline: "Your mind is the scene of the crime.",
        genres: [
            Genre(id: 28, name: "Action"),
            Genre(id: 878, name: "Science Fiction"),
            Genre(id: 53, name: "Thriller")
        ],
        productionCompanies: [
            ProductionCompany(id: 923, name: "Legendary Entertainment", logoPath: "/5UQsaFWVfq5D0Q6bxKrjz8sLjnL.png"),
            ProductionCompany(id: 9996, name: "Syncopy", logoPath: "/5KuHDRubiNRogbA0Q9p8QSbsGKE.png")
        ]
    )
    
    /// Minimal sample movie details for testing edge cases
    static let sampleMinimal = MovieDetails(
        id: 1,
        title: "Test Movie",
        overview: "A simple test movie",
        voteAverage: 7.5,
        voteCount: 100,
        originalLanguage: "en"
    )
}
