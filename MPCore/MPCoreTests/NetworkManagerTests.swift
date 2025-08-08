//
//  NetworkManagerTests.swift
//  MPCore
//
//  Created by mac on 08/08/2025.
//

import XCTest
import Combine
import Moya
@testable import MPCore

final class NetworkManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var networkManager: NetworkManager!
    private var mockProvider: MockMoyaProvider!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockProvider = MockMoyaProvider()
        networkManager = NetworkManager(provider: mockProvider, session: nil)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        networkManager = nil
        mockProvider = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Request Construction and URL Building Tests
    
    func test_requestConstruction_withValidTMDBAPI_buildsCorrectRequest() {
        // Arrange
        let endpoint = TMDBAPI.popularMovies(page: 1)
        
        // Act & Assert
        XCTAssertEqual(endpoint.baseURL.absoluteString, Constants.TMDB.baseURL)
        XCTAssertEqual(endpoint.path, Constants.TMDB.Endpoints.trendingMovies)
        XCTAssertEqual(endpoint.method, .get)
        
        // Verify task contains required parameters
        if case .requestParameters(let parameters, let encoding) = endpoint.task {
            XCTAssertEqual(parameters[Constants.TMDB.QueryParams.apiKey] as? String, Constants.TMDB.apiKey)
            XCTAssertEqual(parameters[Constants.TMDB.QueryParams.language] as? String, Constants.TMDB.Defaults.language)
            XCTAssertEqual(parameters[Constants.TMDB.QueryParams.page] as? Int, 1)
            XCTAssertTrue(encoding is URLEncoding)
        } else {
            XCTFail("Expected requestParameters task")
        }
        
        // Verify headers
        XCTAssertEqual(endpoint.headers?[NetworkConstants.Headers.accept], NetworkConstants.ContentTypes.json)
    }
    
    func test_requestConstruction_withMovieDetailsAPI_buildsCorrectPath() {
        // Arrange
        let movieId = 12345
        let endpoint = TMDBAPI.movieDetails(id: movieId)
        
        // Act & Assert
        XCTAssertEqual(endpoint.path, "\(Constants.TMDB.Endpoints.movieDetails)/\(movieId)")
    }
    
    func test_requestConstruction_withGenresAPI_buildsCorrectPath() {
        // Arrange
        let endpoint = TMDBAPI.genres
        
        // Act & Assert
        XCTAssertEqual(endpoint.path, Constants.TMDB.Endpoints.genres)
        
        // Verify no page parameter for genres
        if case .requestParameters(let parameters, _) = endpoint.task {
            XCTAssertNil(parameters[Constants.TMDB.QueryParams.page])
        } else {
            XCTFail("Expected requestParameters task")
        }
    }
    
    // MARK: - Error Mapping Tests (MoyaError → NetworkError)
    
    func test_errorMapping_moyaStatusCodeError_mapsToCorrectNetworkError() {
        // Arrange
        let testCases: [(statusCode: Int, expectedError: NetworkError)] = [
            (401, .unauthorized),
            (403, .forbidden),
            (404, .notFound),
            (429, .rateLimitExceeded),
            (500, .serverError),
            (502, .serverError),
            (400, .httpError(400))
        ]
        
        for testCase in testCases {
            // Arrange
            let response = HTTPURLResponse(
                url: URL(string: "https://api.example.com")!,
                statusCode: testCase.statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            let moyaResponse = Response(statusCode: testCase.statusCode, data: Data(), request: nil, response: response)
            let moyaError = MoyaError.statusCode(moyaResponse)
            mockProvider.result = .failure(moyaError)
            
            let endpoint = TMDBAPI.genres
            let expectation = self.expectation(description: "Error mapping test for status code \(testCase.statusCode)")
            
            // Act
            networkManager.request(endpoint, type: TestResponseModel.self)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            // Assert
                            switch (error, testCase.expectedError) {
                            case (.unauthorized, .unauthorized),
                                 (.forbidden, .forbidden),
                                 (.notFound, .notFound),
                                 (.rateLimitExceeded, .rateLimitExceeded),
                                 (.serverError, .serverError):
                                break // Success: correct error mapping validated
                            case (.httpError(let code), .httpError(let expectedCode)):
                                XCTAssertEqual(code, expectedCode, "HTTP error code should match")
                            default:
                                XCTFail("Unexpected error mapping: got \(error), expected \(testCase.expectedError)")
                            }
                        } else {
                            XCTFail("Expected NetworkError for status code \(testCase.statusCode)")
                        }
                        expectation.fulfill()
                    },
                    receiveValue: { _ in
                        XCTFail("Should not receive value for error case")
                    }
                )
                .store(in: &cancellables)
            
            waitForExpectations(timeout: 1.0)
        }
    }
    
    func test_errorMapping_moyaDecodingError_mapsToDecodingError() {
        // Arrange
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid JSON"))
        let moyaError = MoyaError.objectMapping(decodingError, Response(statusCode: 200, data: Data()))
        mockProvider.result = .failure(moyaError)
        
        let endpoint = TMDBAPI.genres
        let expectation = self.expectation(description: "Decoding error mapping")
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       case .decodingError = error {
                        // Success: correctly mapped to decoding error
                    } else {
                        XCTFail("Expected decodingError NetworkError")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for error case")
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_errorMapping_urlError_mapsToCorrectNetworkError() {
        // Arrange
        let testCases: [(urlErrorCode: URLError.Code, expectedError: NetworkError)] = [
            (.notConnectedToInternet, .networkUnavailable),
            (.networkConnectionLost, .networkUnavailable),
            (.timedOut, .timeout),
            (.cannotFindHost, .networkUnavailable),
            (.cannotConnectToHost, .networkUnavailable),
            (.dnsLookupFailed, .networkUnavailable),
            (.badURL, .invalidURL)
        ]
        
        for testCase in testCases {
            // Arrange
            let urlError = URLError(testCase.urlErrorCode)
            let moyaError = MoyaError.underlying(urlError, nil)
            mockProvider.result = .failure(moyaError)
            
            let endpoint = TMDBAPI.genres
            let expectation = self.expectation(description: "URL error mapping test for \(testCase.urlErrorCode)")
            
            // Act
            networkManager.request(endpoint, type: TestResponseModel.self)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            // Assert
                            switch (error, testCase.expectedError) {
                            case (.networkUnavailable, .networkUnavailable),
                                 (.timeout, .timeout),
                                 (.invalidURL, .invalidURL):
                                break // Success: correct error mapping validated
                            default:
                                XCTFail("Unexpected error mapping: got \(error), expected \(testCase.expectedError)")
                            }
                        } else {
                            XCTFail("Expected NetworkError for URLError \(testCase.urlErrorCode)")
                        }
                        expectation.fulfill()
                    },
                    receiveValue: { _ in
                        XCTFail("Should not receive value for error case")
                    }
                )
                .store(in: &cancellables)
            
            waitForExpectations(timeout: 1.0)
        }
    }
    
    func test_errorMapping_unknownError_mapsToUnknownError() {
        // Arrange
        let customError = NSError(domain: "TestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Custom test error"])
        let moyaError = MoyaError.underlying(customError, nil)
        mockProvider.result = .failure(moyaError)
        
        let endpoint = TMDBAPI.genres
        let expectation = self.expectation(description: "Unknown error mapping")
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       case .unknown(let underlyingError) = error {
                        XCTAssertEqual((underlyingError as NSError).code, 999)
                        XCTAssertEqual((underlyingError as NSError).domain, "TestError")
                    } else {
                        XCTFail("Expected unknown NetworkError")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for error case")
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Retry Logic Tests
    
    func test_retryLogic_retriesOnFailureUpToMaxAttempts() {
        // Arrange
        let networkError = URLError(.timedOut)
        let moyaError = MoyaError.underlying(networkError, nil)
        mockProvider.result = .failure(moyaError)
        
        let endpoint = TMDBAPI.genres
        let expectation = self.expectation(description: "Retry logic test")
        
        var requestCount = 0
        mockProvider.requestHandler = { _ in
            requestCount += 1
            return self.mockProvider.result!
        }
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    // Assert - Should retry up to NetworkConstants.Defaults.maxRetryAttempts (3) times
                    // Original request + 3 retries = 4 total attempts
                    XCTAssertEqual(requestCount, NetworkConstants.Defaults.maxRetryAttempts + 1)
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for error case")
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 5.0)
    }
    
    func test_retryLogic_successAfterRetry_stopsRetrying() {
        // Arrange
        let endpoint = TMDBAPI.genres
        let successData = TestDataFactory.validJSONData()
        let expectation = self.expectation(description: "Success after retry test")
        
        var requestCount = 0
        mockProvider.requestHandler = { _ in
            requestCount += 1
            if requestCount == 1 {
                // First request fails
                let networkError = URLError(.timedOut)
                let moyaError = MoyaError.underlying(networkError, nil)
                return .failure(moyaError)
            } else {
                // Second request succeeds
                let response = Response(statusCode: 200, data: successData)
                return .success(response)
            }
        }
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        // Assert - Should have made 2 requests (1 failed + 1 successful retry)
                        XCTAssertEqual(requestCount, 2)
                    } else {
                        XCTFail("Expected successful completion")
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    XCTAssertEqual(response.message, "test")
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 3.0)
    }
    
    // MARK: - Response Decoding Tests
    
    func test_responseDecoding_validJSON_decodesSuccessfully() {
        // Arrange
        let validJSONData = TestDataFactory.validJSONData()
        let response = Response(statusCode: 200, data: validJSONData)
        mockProvider.result = .success(response)
        
        let endpoint = TMDBAPI.genres
        let expectation = self.expectation(description: "Valid JSON decoding")
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    // Assert
                    XCTAssertEqual(response.message, "test")
                    XCTAssertEqual(response.count, 42)
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_responseDecoding_invalidJSON_failsGracefully() {
        // Arrange
        let invalidJSONData = TestDataFactory.invalidJSONData()
        let response = Response(statusCode: 200, data: invalidJSONData)
        mockProvider.result = .success(response)
        
        let endpoint = TMDBAPI.genres
        let expectation = self.expectation(description: "Invalid JSON decoding")
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       case .decodingError = error {
                        // Success: correctly handled invalid JSON
                    } else {
                        XCTFail("Expected decodingError NetworkError")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for invalid JSON")
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_responseDecoding_emptyJSON_failsGracefully() {
        // Arrange
        let emptyData = Data()
        let response = Response(statusCode: 200, data: emptyData)
        mockProvider.result = .success(response)
        
        let endpoint = TMDBAPI.genres
        let expectation = self.expectation(description: "Empty JSON decoding")
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       case .decodingError = error {
                        // Success: correctly handled empty data
                    } else {
                        XCTFail("Expected decodingError NetworkError")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for empty data")
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_responseDecoding_wrongStructure_failsWithDecodingError() {
        // Arrange
        let wrongStructureData = TestDataFactory.wrongStructureJSONData()
        let response = Response(statusCode: 200, data: wrongStructureData)
        mockProvider.result = .success(response)
        
        let endpoint = TMDBAPI.genres
        let expectation = self.expectation(description: "Wrong structure JSON decoding")
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       case .decodingError = error {
                        // Success: correctly handled wrong structure
                    } else {
                        XCTFail("Expected decodingError NetworkError")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for wrong structure")
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Timeout Handling Tests
    
    func test_timeoutHandling_timedOutError_mapsToTimeoutError() {
        // Arrange
        let timeoutError = URLError(.timedOut)
        let moyaError = MoyaError.underlying(timeoutError, nil)
        mockProvider.result = .failure(moyaError)
        
        let endpoint = TMDBAPI.genres
        let expectation = self.expectation(description: "Timeout error handling")
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion,
                       case .timeout = error {
                        // Success: correctly mapped timeout error
                    } else {
                        XCTFail("Expected timeout NetworkError")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value for timeout error")
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Integration Tests
    
    func test_integration_fullSuccessFlow_worksEndToEnd() {
        // Arrange
        let validJSONData = TestDataFactory.validJSONData()
        let response = Response(statusCode: 200, data: validJSONData)
        mockProvider.result = .success(response)
        
        let endpoint = TMDBAPI.popularMovies(page: 1)
        let expectation = self.expectation(description: "Full success flow")
        
        // Act
        networkManager.request(endpoint, type: TestResponseModel.self)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        // Success: request completed successfully
                    } else {
                        XCTFail("Expected successful completion")
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    // Assert
                    XCTAssertEqual(response.message, "test")
                    XCTAssertEqual(response.count, 42)
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_integration_multipleSimultaneousRequests_handleCorrectly() {
        // Arrange
        let validJSONData = TestDataFactory.validJSONData()
        let response = Response(statusCode: 200, data: validJSONData)
        mockProvider.result = .success(response)
        
        let endpoints = [
            TMDBAPI.genres,
            TMDBAPI.popularMovies(page: 1),
            TMDBAPI.movieDetails(id: 123)
        ]
        
        let expectation = self.expectation(description: "Multiple simultaneous requests")
        expectation.expectedFulfillmentCount = endpoints.count
        
        // Act
        endpoints.forEach { endpoint in
            networkManager.request(endpoint, type: TestResponseModel.self)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            XCTFail("Unexpected error: \(error)")
                        }
                        expectation.fulfill()
                    },
                    receiveValue: { response in
                        XCTAssertEqual(response.message, "test")
                    }
                )
                .store(in: &cancellables)
        }
        
        waitForExpectations(timeout: 3.0)
    }
}

// MARK: - Test Utilities

/// Mock Moya Provider for testing NetworkManager
private class MockMoyaProvider: MoyaProvider<MultiTarget> {
    
    var result: Result<Response, MoyaError>!
    var requestHandler: ((TargetType) -> Result<Response, MoyaError>)?
    
    override func request(_ target: MultiTarget, callbackQueue: DispatchQueue? = nil, progress: ProgressBlock? = nil, completion: @escaping Completion) -> Moya.Cancellable {
        
        let actualResult = requestHandler?(target.target) ?? result!
        
        // Simulate async behavior
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            completion(actualResult)
        }
        
        return SimpleCancellable()
    }
}

/// Simple cancellable implementation for testing
private class SimpleCancellable: Moya.Cancellable {
    public var isCancelled = false
    
    public func cancel() {
        isCancelled = true
    }
    
    public var isCanceled: Bool {
        return isCancelled
    }
}

/// Test response model for decoding tests
private struct TestResponseModel: Codable {
    let message: String
    let count: Int
}

/// Factory for creating test data
private struct TestDataFactory {
    
    static func validJSONData() -> Data {
        let json = """
        {
            "message": "test",
            "count": 42
        }
        """
        return json.data(using: .utf8)!
    }
    
    static func invalidJSONData() -> Data {
        let invalidJson = """
        {
            "message": "test",
            "count": 42,
            "invalid": 
        """
        return invalidJson.data(using: .utf8)!
    }
    
    static func wrongStructureJSONData() -> Data {
        let wrongStructureJson = """
        {
            "wrong_field": "value",
            "another_wrong_field": 123
        }
        """
        return wrongStructureJson.data(using: .utf8)!
    }
    
    static func createMockResponse(statusCode: Int, data: Data) -> Response {
        let url = URL(string: "https://api.test.com")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let urlRequest = URLRequest(url: url)
        
        return Response(
            statusCode: statusCode,
            data: data,
            request: urlRequest,
            response: httpResponse
        )
    }
}
