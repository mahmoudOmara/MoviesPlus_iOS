//
//  NetworkManager.swift
//  MPCore
//
//  Created by mac on 04/08/2025.
//


import Foundation
import Combine
import Moya
import CombineMoya

/// Main network manager for TMDB API integration
/// Provides Combine-based networking with error handling and caching
public final class NetworkManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Moya provider for TMDB API
    private let provider: MoyaProvider<MultiTarget>
    
    /// URL session for custom networking needs
    private let session: URLSession
    
    
    // MARK: - Initialization
    
    public init(
        provider: MoyaProvider<MultiTarget>? = nil,
        session: URLSession? = nil
    ) {
        // Configure URL session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConstants.Timeouts.request
        configuration.timeoutIntervalForResource = NetworkConstants.Timeouts.resource
        configuration.urlCache = URLCache(
            memoryCapacity: NetworkConstants.Defaults.cacheSize,
            diskCapacity: NetworkConstants.Defaults.cacheSize,
            diskPath: "network_cache"
        )
        
        self.session = session ?? URLSession(configuration: configuration)
        
        // Configure Moya provider
        self.provider = provider ?? MoyaProvider<MultiTarget>(
            plugins: [
                NetworkLoggerPlugin(configuration: .init(
                    formatter: .init(responseData: JSONResponseDataFormatter),
                    logOptions: Constants.Development.enableLogging ? .verbose : .default
                ))
            ]
        )
    }
    
    // MARK: - Public Methods
    
    /// Makes a network request and returns a Combine publisher
    /// - Parameters:
    ///   - target: The TMDB service target
    ///   - type: The expected response type
    /// - Returns: Publisher that emits the decoded response or an error
    public func request<T: Decodable>(
        _ target: TargetType,
        type: T.Type
    ) -> AnyPublisher<T, NetworkError> {
                
        return provider
            .requestPublisher(MultiTarget(target))
            .map(\.data)
            .decode(type: type, decoder: JSONDecoder.apiDecoder)
            .mapError { error in
                if let moyaError = error as? MoyaError {
                    return self.mapMoyaError(moyaError)
                } else if let decodingError = error as? DecodingError {
                    return NetworkError.decodingError(decodingError)
                } else {
                    return NetworkError.unknown(error)
                }
            }
            .retry(NetworkConstants.Defaults.maxRetryAttempts)
            .eraseToAnyPublisher()
    }
    
    
    // MARK: - Private Methods
    
    private func mapMoyaError(_ error: MoyaError) -> NetworkError {
        switch error {
        case .imageMapping, .jsonMapping, .stringMapping, .encodableMapping:
            return .decodingError(error)
        case .statusCode(let response):
            return NetworkError.fromStatusCode(response.statusCode)
        case .underlying(let nsError, _):
            if let urlError = nsError as? URLError {
                return NetworkError.fromURLError(urlError)
            }
            return .unknown(nsError)
        case .objectMapping(let error, _):
            return .decodingError(error)
        case .requestMapping:
            return .invalidURL
        case .parameterEncoding(let error):
            return .unknown(error)
        @unknown default:
            return .unknown(error)
        }
    }
}

// MARK: - Singleton Access

public extension NetworkManager {
    
    /// Shared instance of NetworkManager
    static let shared = NetworkManager()
}

// MARK: - Response Data Formatter

fileprivate func JSONResponseDataFormatter(_ data: Data) -> String {
    do {
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        return String(data: pretty, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
    } catch {
        return String(data: data, encoding: .utf8) ?? ""
    }
}
