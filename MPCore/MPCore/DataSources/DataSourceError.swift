//
//  DataSourceError.swift
//  MPCore
//
//  Created by mac on 04/08/2025.
//

import Foundation

/// Specific errors that can occur in the remote data source
public enum DataSourceError: LocalizedError {
    case networkUnavailable
    case unauthorized
    case dataNotFound
    case rateLimitExceeded
    case serverError
    case invalidResponse
    case networkError(Error)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection is not available"
        case .unauthorized:
            return "API key is invalid or unauthorized"
        case .dataNotFound:
            return "The requested data was not found"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later"
        case .serverError:
            return "Server is currently unavailable"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available"
        case .unauthorized:
            return "Invalid API credentials"
        case .dataNotFound:
            return "Resource not found on server"
        case .rateLimitExceeded:
            return "Too many requests made to the API"
        case .serverError:
            return "Server is experiencing issues"
        case .invalidResponse:
            return "Server returned invalid data format"
        case .networkError:
            return "Network request failed"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}
