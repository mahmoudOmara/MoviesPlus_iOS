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
    
    /// Searches for movies by query text in the cached movies
    /// - Parameters:
    ///   - query: Search query text
    /// - Returns: Publisher emitting array of movies or error
    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error>
    
    /// Filters cached movies by genre IDs and sorts them according to the specified option
    /// - Parameters:
    ///   - genreIds: Array of genre IDs to filter by (empty array means no genre filter)
    ///   - sortOption: The sort option to apply
    ///   - page: Page number for pagination (starting from 1)
    /// - Returns: Publisher emitting filtered and sorted movies
    func filterAndSortMovies(genreIds: [Int], sortOption: MovieSortOption, page: Int) -> AnyPublisher<[Movie], Error>
}
