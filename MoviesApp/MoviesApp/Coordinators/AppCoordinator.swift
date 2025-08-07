//
//  AppCoordinator.swift
//  MoviesApp
//
//  Created by mac on 07/08/2025.
//

import SwiftUI
import MPCore
import MPMoviesListing
import MPMovieDetails

/// Navigation states for the main app flow
public enum AppNavigationDestination: Hashable {
    case movieListing
    case movieDetails(movieId: Int)
}

/// Root coordinator for the entire application
/// Manages navigation between different feature modules
@MainActor
public final class AppCoordinator: Coordinator, ObservableObject {
    
    // MARK: - Coordinator Properties
    
    public var parentCoordinator: (any Coordinator)?

    @Published public var path = NavigationPath()
    
    // MARK: - Child Coordinators

    private var movieListingCoordinator: MovieListingCoordinator?
    private var movieDetailsCoordinator: MovieDetailsCoordinator?

    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Coordinator Methods
    
    public func start() -> AnyView {
        return destination(for: .movieListing) ?? AnyView(EmptyView())
    }
    
    public func navigate(to destination: AppNavigationDestination) {
        switch destination {
        case .movieListing:
            path = NavigationPath()
        default:
            path.append(destination)
        }
    }
    
    public func destination(for destination: AppNavigationDestination) -> AnyView? {
        switch destination {
        case .movieListing:
            movieListingCoordinator = MovieListingCoordinator(delegate: self)
//            movieListingCoordinator?.parentCoordinator = self
            return AnyView(movieListingCoordinator!.start())
            
        case .movieDetails(let movieId):
            movieDetailsCoordinator = MovieDetailsCoordinator(movieId: movieId, delegate: self)
//            movieDetailsCoordinator?.parentCoordinator = self
            return AnyView(movieDetailsCoordinator!.start())

        }
    }
}

extension AppCoordinator: MovieListingCoordinatorDelegate {
    public func navigateToMovieDetails(movieId: Int) {
        self.navigate(to: .movieDetails(movieId: movieId))
    }
}

extension AppCoordinator: MovieDetailsCoordinatorDelegate {
    public func navigateBack() {
        self.navigate(to: .movieListing)
    }
}
