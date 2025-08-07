//
//  MoviesAppApp.swift
//  MoviesApp
//
//  Created by mac on 04/08/2025.
//

import SwiftUI
import MPCore
import MPMoviesListing

@main
struct MoviesAppApp: App {
    private let appCoordinator: AppCoordinator

    init() {
        do {
            try SwiftDataStack.configureShared(with: [LocalMovieModel.self])
        } catch {
            fatalError("Failed to configure SwiftDataStack: \(error)")
        }
        
        self.appCoordinator = AppCoordinator()
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: appCoordinator)
                .themedEnvironment()
        }
    }
}
