//
//  InterModuleCoordinator.swift
//  MPCore
//
//  Created by mac on 08/08/2025.
//

import Foundation

/// Protocol for coordinators that can handle inter-module navigation
/// This allows child coordinators to navigate between modules without tight coupling
@MainActor
public protocol InterModuleCoordinator: Coordinator {
    func navigateToMovieDetails(movieId: Int)
    func navigateBack()
}
