//
//  GetGenresUseCase.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation
import MPCore
import Combine

/// Use case for getting movie genres with caching and filtering support
/// Manages genre data access and provides filtering capabilities
public final class GetGenresUseCase {
    
    // MARK: - Properties
    
    private let repository: MovieRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Use Case Methods
    
    /// Executes the use case to get all genres
    /// - Returns: Publisher emitting array of genres or error
    public func execute() -> AnyPublisher<[Genre], Error> {
        return repository.getGenres()
    }
}
