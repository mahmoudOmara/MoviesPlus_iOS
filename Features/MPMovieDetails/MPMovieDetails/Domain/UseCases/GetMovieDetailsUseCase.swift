//
//  GetMovieDetailsUseCase.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//


import Foundation
import Combine
import MPCore

/// Use case for fetching comprehensive movie details
/// Encapsulates the business logic for getting movie information
public final class GetMovieDetailsUseCase {
    
    // MARK: - Properties
    
    private let repository: MovieDetailsRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(repository: MovieDetailsRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// Executes the use case to get movie details
    /// - Parameter movieId: The movie ID to fetch details for
    /// - Returns: Publisher emitting movie details or error
    public func execute(movieId: Int) -> AnyPublisher<MovieDetails, Error> {
        
        // Validate input
        guard movieId > 0 else {
            return Fail(error: UseCaseError.invalidMovieId)
                .eraseToAnyPublisher()
        }
        
        return repository.getMovieDetails(movieId: movieId)
    }
}
