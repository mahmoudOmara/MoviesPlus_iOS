//
//  NetworkError.swift
//  MPCore
//
//  Created by mac on 04/08/2025.
//


import Foundation

/// Network-specific errors
public enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case httpError(Int)
    case networkUnavailable
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case rateLimitExceeded
    case serverError
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error with code: \(code)"
        case .networkUnavailable:
            return "Network unavailable"
        case .timeout:
            return "Request timeout"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError:
            return "Server error"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidURL:
            return "The URL provided is malformed"
        case .noData:
            return "The server returned no data"
        case .decodingError:
            return "The response data could not be parsed"
        case .httpError(let code):
            return "The server returned HTTP status code \(code)"
        case .networkUnavailable:
            return "No internet connection is available"
        case .timeout:
            return "The request took too long to complete"
        case .unauthorized:
            return "Authentication credentials are invalid"
        case .forbidden:
            return "You don't have permission to access this resource"
        case .notFound:
            return "The requested resource could not be found"
        case .rateLimitExceeded:
            return "Too many requests have been made"
        case .serverError:
            return "The server encountered an internal error"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}

// MARK: - Error Mapping

public extension NetworkError {
    
    /// Maps HTTP status codes to appropriate errors
    /// - Parameter statusCode: The HTTP status code
    /// - Returns: The corresponding NetworkError
    static func fromStatusCode(_ statusCode: Int) -> NetworkError {
        switch statusCode {
        case 200...299:
            return .unknown(NSError(domain: "NetworkError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected success code in error mapping"]))
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimitExceeded
        case 500...599:
            return .serverError
        default:
            return .httpError(statusCode)
        }
    }
    
    /// Maps URLError to NetworkError
    /// - Parameter urlError: The URLError to map
    /// - Returns: The corresponding NetworkError
    static func fromURLError(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .timeout
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .networkUnavailable
        case .badURL:
            return .invalidURL
        default:
            return .unknown(urlError)
        }
    }
}
