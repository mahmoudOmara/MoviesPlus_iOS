//
//  FilterAndSortMoviesUseCase.swift
//  MPMoviesListing
//
//  Created by mac on 06/08/2025.
//

import Foundation
import Combine
import MPCore

/// Use case for filtering movies by genre and sorting them
/// Handles filtering and sorting functionality with validation
public final class FilterAndSortMoviesUseCase {
    
    // MARK: - Properties
    
    private let repository: MovieRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Use Case Methods
    
    /// Executes the filter and sort use case
    /// - Parameters:
    ///   - genreIds: Array of genre IDs to filter by (empty array means no genre filter)
    ///   - sortOption: The sort option to apply
    ///   - page: Page number for pagination (starting from 1)
    /// - Returns: Publisher emitting filtered and sorted movies or error
    public func execute(genreIds: [Int], sortOption: MovieSortOption, page: Int) -> AnyPublisher<[Movie], Error> {
        // Validate inputs
        guard page > 0 else {
            return Fail(error: UseCaseError.invalidPage)
                .eraseToAnyPublisher()
        }
        
        return repository.filterAndSortMovies(genreIds: genreIds, sortOption: sortOption, page: page)
    }
}
