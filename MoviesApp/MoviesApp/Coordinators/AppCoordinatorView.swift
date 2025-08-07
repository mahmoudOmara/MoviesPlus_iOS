//
//  AppCoordinatorView.swift
//  MoviesApp
//
//  Created by mac on 07/08/2025.
//

import SwiftUI

/// A SwiftUI view that wraps a coordinator for integration with SwiftUI navigation
public struct AppCoordinatorView: View {
    
    @ObservedObject private var coordinator: AppCoordinator
    
    private let startView: AnyView

    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        startView = coordinator.start()
    }
    
    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            startView
                .navigationDestination(for: AppNavigationDestination.self) { destination in
                    self.coordinator.destination(for: destination)
                }
        }
    }
}
