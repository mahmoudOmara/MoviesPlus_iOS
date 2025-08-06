//
//  ViewModelState.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//


import Foundation

/// Generic state enum for handling different UI states across the application
/// Provides type-safe state management for ViewModels
public enum ViewModelState<T> {
    case idle
    case loading
    case loadingMore
    case success(T)
    case failure(Error)
}

// MARK: - Convenience Properties
public extension ViewModelState {
    
    /// Returns true if the state is idle
    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }
    
    /// Returns true if the state is loading
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    /// Returns true if the state is loadingMore
    var isLoadingMore: Bool {
        if case .loadingMore = self {
            return true
        }
        return false
    }
    
    /// Check if state is failure
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    /// Check if state is failure
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
    
    /// Returns the success value if available
    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    /// Returns the error if available
    var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
    
    /// Returns true if the state has a value (success state)
    var hasValue: Bool {
        value != nil
    }
    
    /// Returns true if the state has an error (failure state)
    var hasError: Bool {
        error != nil
    }
}

// MARK: - Equatable Conformance
extension ViewModelState: Equatable where T: Equatable {
    public static func == (lhs: ViewModelState<T>, rhs: ViewModelState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loadingMore, .loadingMore):
            return true
        case (.success(let lhsValue), .success(let rhsValue)):
            return lhsValue == rhsValue
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
