//
//  MovieDetailsDestination.swift
//  MPMovieDetails
//
//  Created by mac on 07/08/2025.
//

import SwiftUI
import MPCore

/// Navigation states for movie details module
public enum MovieDetailsDestination: Hashable {
    case back
}

/// Protocol for paret coordinator that can handle movie details navigation
@MainActor
public protocol MovieDetailsCoordinatorDelegate: AnyObject {
    func navigateBack()
}

@MainActor
public final class MovieDetailsCoordinator: Coordinator, ObservableObject {
    public typealias Destination = MovieDetailsDestination
    
    // MARK: - Coordinator Properties
    
    public var parentCoordinator: (any Coordinator)?
    
    private weak var delegate: MovieDetailsCoordinatorDelegate?
    
    @Published public var path = NavigationPath() //Never used as all navigations are delegated to parent coordinator
        
    // MARK: - Dependencies
    
    private let movieId: Int
    
    // MARK: - Initialization
    
    public init(movieId: Int, delegate: MovieDetailsCoordinatorDelegate?) {
        self.movieId = movieId
        self.delegate = delegate
    }
    
    // MARK: - Coordinator Methods
    
    public func start() -> AnyView {
        return AnyView(createMovieDetailsView())
    }
    
    public func navigate(to destination: MovieDetailsDestination) {
        switch destination {
        case .back:
            delegate?.navigateBack()
        }
    }
    
    // MARK: - Public Methods
    
    public func createMovieDetailsView() -> some View {
        // Create repository and view model
        let localDataSource = MovieDetailsLocalDataSource(swiftDataStack: SwiftDataStack.shared)
        let remoteDataSource = MovieDetailsRemoteDataSource(networkManager: NetworkManager.shared)
        let repository = MovieDetailsRepository(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource
        )
        
        let viewModel = MovieDetailsViewModel(
            movieId: movieId,
            repository: repository,
            coordinator: self,
            sharingService: SharingService()
        )
        
        return MovieDetailsView(viewModel: viewModel)
    }
}
