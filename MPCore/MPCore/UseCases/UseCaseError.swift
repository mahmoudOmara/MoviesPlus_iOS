//
//  UseCaseError.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//

import Foundation

public enum UseCaseError: LocalizedError {
    case invalidPage
    case noData
    case networkError
    case cacheError
    case tooShortSearchQuery(minimumLength: Int)
    case invalidMovieId
    
    public var errorDescription: String? {
        switch self {
        case .invalidPage:
            return "Invalid page number provided"
        case .noData:
            return "No data available"
        case .networkError:
            return "Network request failed"
        case .cacheError:
            return "Cache operation failed"
        case .tooShortSearchQuery(let minimumLength):
            return "Search query must be at least \(minimumLength) characters long"
        case .invalidMovieId:
            return "Invalid movie ID provided"
        }
    }
}
