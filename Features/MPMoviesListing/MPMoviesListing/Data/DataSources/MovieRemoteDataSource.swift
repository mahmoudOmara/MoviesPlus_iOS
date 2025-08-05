//
//  MovieRemoteDataSource.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation
import Combine
import MPCore

/// Remote data source for fetching movie data from TMDB API
/// Handles all network operations for the MovieList feature
public final class MovieRemoteDataSource {
    
    // MARK: - Properties
    
    private let networkManager: NetworkManager
    
    // MARK: - Initialization
    
    public init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Movie Operations
    
    /// Fetches popular movies from TMDB API
    /// - Parameter page: Page number for pagination (starting from 1)
    /// - Returns: Publisher emitting movie response model or error
    public func getPopularMovies(page: Int) -> AnyPublisher<MovieResponseModel, Error> {
        return networkManager.request(TMDBAPI.popularMovies(page: page), type: MovieResponseModel.self)
            .mapError { error in
                self.mapNetworkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Genre Operations
    
    /// Fetches all available genres from TMDB API
    /// - Returns: Publisher emitting genre response model or error
    public func getGenres() -> AnyPublisher<GenreResponseModel, Error> {
        return networkManager.request(TMDBAPI.genres, type: GenreResponseModel.self)
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
