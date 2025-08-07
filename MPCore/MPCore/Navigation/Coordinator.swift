//
//  Coordinator.swift
//  MPCore
//
//  Created by mac on 07/08/2025.
//


import SwiftUI

/// Base protocol for all coordinators in the application
/// Provides a common interface for navigation management
@MainActor
public protocol Coordinator: ObservableObject {
    
    /// Associated type for the navigation destinations this coordinator handles
    associatedtype Destination: Hashable

    /// Parent coordinator for delegation of inter-module navigation
    var parentCoordinator: (any Coordinator)? { get set }

    var path: NavigationPath { get set }

    /// Starts the coordinator and returns the initial view
    func start() -> AnyView
    
    /// Handles navigation to a specific destination
    func navigate(to destination: Destination)
    
}
