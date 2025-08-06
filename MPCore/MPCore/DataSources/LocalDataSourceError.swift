//
//  LocalDataSourceError.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//

import Foundation

/// Specific errors that can occur in the local data source
public enum LocalDataSourceError: LocalizedError {
    case operationFailed
    case saveFailed(Error)
    case fetchFailed(Error)
    case deletionFailed(Error)
    case insertionFailed(Error)
    case dataCorrupted
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .operationFailed:
            return "Local data operation failed"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deletionFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .insertionFailed(let error):
            return "Failed to insert data: \(error.localizedDescription)"
        case .dataCorrupted:
            return "Local data is corrupted"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
