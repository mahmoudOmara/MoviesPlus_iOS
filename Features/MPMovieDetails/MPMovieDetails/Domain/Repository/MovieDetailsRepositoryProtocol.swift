//
//  MovieDetailsRepositoryProtocol.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import Combine
//import MPCore

/// Repository protocol for movie details operations
/// Follows the Repository pattern to abstract data access
public protocol MovieDetailsRepositoryProtocol {
    
    // MARK: - Movie Details Operations
    
    /// Fetches detailed information for a specific movie
    /// - Parameter movieId: The movie ID to fetch details for
    /// - Returns: Publisher emitting movie details or error
    func getMovieDetails(movieId: Int) -> AnyPublisher<MovieDetails?, Error>
}
