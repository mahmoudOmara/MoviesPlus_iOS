//
//  SwiftDataError.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//

import Foundation

/// Persistance-specific errors
public enum SwiftDataError: LocalizedError {
    case operationFailed
    case containerInitializationFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deletionFailed(Error)
    case insertionFailed(Error)
    case modelNotFound
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .operationFailed:
            return "Local data operation failed"
        case .containerInitializationFailed(let error):
            return "Failed to initialize model container: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deletionFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .insertionFailed(let error):
            return "Failed to insert data: \(error.localizedDescription)"
        case .modelNotFound:
            return "Requested model not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}
