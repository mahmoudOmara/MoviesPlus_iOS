//
//  GetMoviesUseCase.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation
import MPCore
import Combine

/// Use case for getting popular movies with pagination
/// Encapsulates the business logic for fetching and managing movie data
public final class GetMoviesUseCase {
    
    // MARK: - Properties
    
    private let repository: MovieRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Use Case Methods
    
    /// Executes the use case to get popular movies
    /// - Parameter page: Page number for pagination (starting from 1)
    /// - Returns: Publisher emitting array of movies or error
    public func execute(page: Int) -> AnyPublisher<[Movie], Error> {
        guard page > 0 else {
            return Fail(error: UseCaseError.invalidPage)
                .eraseToAnyPublisher()
        }
        
        return repository.getPopularMovies(page: page)
    }
    
}
