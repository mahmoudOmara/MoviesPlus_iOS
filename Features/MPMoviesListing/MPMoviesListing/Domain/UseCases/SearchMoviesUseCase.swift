//
//  SearchMoviesUseCase.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation
import Combine
import MPCore

/// Use case for searching movies with query validation
/// Handles search functionality
public final class SearchMoviesUseCase {
    
    // MARK: - Properties
    
    private let repository: MovieRepositoryProtocol
    private let minimumQueryLength: Int
    
    // MARK: - Initialization
    
    public init(repository: MovieRepositoryProtocol, minimumQueryLength: Int = 2) {
        self.repository = repository
        self.minimumQueryLength = minimumQueryLength
    }
    
    // MARK: - Use Case Methods
    
    /// Executes the search use case
    /// - Parameters:
    ///   - query: Search query text
    ///   - page: Page number for pagination (starting from 1)
    /// - Returns: Publisher emitting array of movies or error
    public func execute(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        // Validate inputs
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedQuery.count >= minimumQueryLength else {
            return Fail(error: UseCaseError.tooShortSearchQuery(minimumLength: minimumQueryLength))
                .eraseToAnyPublisher()
        }
        
        return repository.searchMovies(query: trimmedQuery, page: page)
    }
    
}
