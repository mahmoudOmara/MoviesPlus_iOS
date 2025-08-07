//
//  BaseViewModel.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//

import Foundation
import Combine
import SwiftUI

/// Base ViewModel class providing common functionality for all ViewModels
/// Uses ViewModelState for unified state management
open class BaseViewModel<T,C: Coordinator>: ObservableObject {
    
    // MARK: - Coordinator
    
    /// Coordinator for handling navigation - use weak reference to prevent retain cycles
    public weak var coordinator: C?

    // MARK: - Published Properties
    
    /// Common state property using ViewModelState enum
    @Published public var state: ViewModelState<T> = .idle
    
    // MARK: - Private Properties
    
    /// Set to store cancellables for Combine subscriptions
    public var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(coordinator: C? = nil) {
        self.coordinator = coordinator
    }
    // MARK: - Public Methods
    
    /// Sets the state to loading
    public func setLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .loading
        }
    }
    
    /// Sets the state to loadingMore
    public func setLoadingMore() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .loadingMore
        }
    }
    
    /// Sets the state to success with data
    /// - Parameter data: The success data
    public func setSuccess(_ data: T) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .success(data)
        }
    }
    
    /// Sets the state to failure with error
    /// - Parameter error: The error to handle
    public func setFailure(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .failure(error)
        }
    }
    
    /// Resets the state to idle
    public func resetState() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .idle
        }
    }
    
    // MARK: - Convenience Properties
    
    /// Returns true if the state is loading
    public var isLoading: Bool {
        state.isLoading
    }
    
    /// Returns true if the state is loading
    public var isLoadingMore: Bool {
        state.isLoadingMore
    }
    
    /// Returns true if the state has an error
    public var hasError: Bool {
        state.hasError
    }
    
    /// Returns the error if available
    public var error: Error? {
        state.error
    }
    
    /// Returns the success data if available
    public var data: T? {
        state.value
    }
    
    /// Returns true if the state has success data
    public var hasData: Bool {
        state.hasValue
    }
    
    // MARK: - Lifecycle
    
    deinit {
        cancellables.removeAll()
    }
}
