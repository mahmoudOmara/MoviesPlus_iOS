//
//  RepositoryError.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//

import Foundation

/// Errors that can occur within the MovieRepository
public enum RepositoryError: LocalizedError {
    case remote(RemoteDataSourceError)
    case local(LocalDataSourceError)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .remote(let error):
            return error.errorDescription
        case .local(let error):
            return error.errorDescription
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .remote(let error):
            return error.failureReason
        case .local(let error):
            return error.failureReason
        case .unknown:
            return "Unknown repository error"
        }
    }
}
