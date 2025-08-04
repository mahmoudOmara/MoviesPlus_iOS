//
//  MovieRepositoryProtocol.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation
import Combine

/// Repository protocol defining data access contracts for the MovieList feature
/// This protocol abstracts the data layer and provides a clean interface for use cases
public protocol MovieRepositoryProtocol {
    
    // MARK: - Movie Operations
    
    /// Fetches popular movies with pagination
    /// - Parameter page: Page number for pagination (starting from 1)
    /// - Returns: Publisher emitting array of movies or error
    func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error>
        
    // MARK: - Genre Operations
    
    /// Fetches all available movie genres
    /// - Returns: Publisher emitting array of genres or error
    func getGenres() -> AnyPublisher<[Genre], Error>
    
    // MARK: - Cache Operations
    
    /// Gets cached movies for offline usage
    /// - Parameter page: Page number for pagination
    /// - Returns: Publisher emitting cached movies or error
    func getCachedMovies(page: Int) -> AnyPublisher<[Movie], Error>
    
    /// Gets cached genres
    /// - Returns: Publisher emitting cached genres or error
    func getCachedGenres() -> AnyPublisher<[Genre], Error>
}
