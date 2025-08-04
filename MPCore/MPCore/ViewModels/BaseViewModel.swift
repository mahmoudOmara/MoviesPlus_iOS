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
/// Includes loading state management, and error handling
open class BaseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// General loading state for the entire ViewModel
    @Published public var isLoading: Bool = false
    
    /// General error state for displaying alerts or error messages
    @Published public var errorMessage: String?
    
    /// Flag to show/hide error alerts
    @Published public var showError: Bool = false
    
    // MARK: - Private Properties
    
    /// Set to store cancellables for Combine subscriptions
    public var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Handles errors by setting error message and showing error state
    /// - Parameter error: The error to handle
    public func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
            self?.showError = true
        }
    }
    
    /// Clears the current error state
    public func clearError() {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = nil
            self?.showError = false
        }
    }
    
    /// Sets loading state manually
    /// - Parameter loading: Whether loading should be shown
    public func setLoading(_ loading: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = loading
        }
    }
    
    // MARK: - Lifecycle
    
    deinit {
        cancellables.removeAll()
    }
}
