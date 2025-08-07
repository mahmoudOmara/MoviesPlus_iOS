//
//  MovieListingCoordinatorDelegate.swift
//  MPMovieDetails
//
//  Created by mac on 07/08/2025.
//


import SwiftUI
import MPCore

/// Navigation states for movie listing module
public enum MovieListingDestination: Hashable {
    case movieDetails(movieId: Int)
}

/// Coordinator for the Movie Listing module
/// Manages navigation within the movie listing feature
@MainActor
public final class MovieListingCoordinator: Coordinator, ObservableObject {
    
    // MARK: - Coordinator Properties
    
    public weak var parentCoordinator: (any Coordinator)?
        
    @Published public var path = NavigationPath() //Never used as all navigations are delegated to parent coordinator

    @Published var selectedMovieId: Int? = nil
        
    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Coordinator Methods
    
    public func start() -> AnyView {
        return AnyView(createMovieListView())
    }
    
    public func navigate(to destination: MovieListingDestination) {
        switch destination {
        case .movieDetails(let movieId):
            (parentCoordinator as? (any InterModuleCoordinator))?.navigateToMovieDetails(movieId: movieId)
        }
    }
    
    // MARK: - Private Helpers

    private func createMovieListView() -> some View {
        // Create repository and view model
        let localDataSource = MovieLocalDataSource(swiftDataStack: SwiftDataStack.shared)
        let remoteDataSource = MovieRemoteDataSource(networkManager: NetworkManager.shared)
        let repository = MovieRepository(remoteDataSource: remoteDataSource, localDataSource: localDataSource)
        
        let viewModel = MovieListViewModel(repository: repository, coordinator: self)

        return MovieListView(viewModel: viewModel)
    }
}
