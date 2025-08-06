//
//  MovieDetailsRemoteDataSource.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import Combine
import MPCore

/// Remote data source for fetching movie details from TMDB API
/// Handles all network operations for the MovieDetails feature
public final class MovieDetailsRemoteDataSource {
    
    // MARK: - Properties
    
    private let networkManager: NetworkManager
    
    // MARK: - Initialization
    
    public init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Movie Details Operations
    
    /// Fetches detailed movie information from TMDB API
    /// - Parameter movieId: The movie ID to fetch details for
    /// - Returns: Publisher emitting movie details response or error
    public func getMovieDetails(movieId: Int) -> AnyPublisher<MovieDetailsResponseModel, Error> {
        return networkManager.request(TMDBAPI.movieDetails(id: movieId), type: MovieDetailsResponseModel.self)
            .mapError { error in
                self.mapNetworkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helpers
    
    /// Maps network errors to data source specific errors
    /// - Parameter error: Original network error
    /// - Returns: Mapped data source error
    private func mapNetworkError(_ error: Error) -> RemoteDataSourceError {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .networkUnavailable, .timeout:
                return .networkUnavailable
            case .unauthorized:
                return .unauthorized
            case .notFound:
                return .dataNotFound
            case .rateLimitExceeded:
                return .rateLimitExceeded
            case .serverError:
                return .serverError
            default:
                return .networkError(networkError)
            }
        }
        
        return .unknown(error)
    }
}
