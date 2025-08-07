//
//  MovieDetailsLocalDataSource.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import Combine
import SwiftData
import MPCore

/// Local data source for managing cached movie details data using SwiftData
/// Handles all local storage operations for the MovieDetails feature
public final class MovieDetailsLocalDataSource {
    
    // MARK: - Properties
    
    private let swiftDataStack: SwiftDataStack
    private let moviesCacheDuration: TimeInterval
    private let genresCacheDuration: TimeInterval

    // MARK: - Initialization
    
    public init(
        swiftDataStack: SwiftDataStack = SwiftDataStack.shared,
        moviesCacheDuration: TimeInterval = Constants.Persistence.Cache.moviesCacheDuration,
        genresCacheDuration: TimeInterval = Constants.Persistence.Cache.genresCacheDuration
    ) {
        self.swiftDataStack = swiftDataStack
        self.moviesCacheDuration = moviesCacheDuration
        self.genresCacheDuration = genresCacheDuration
    }
    
    // MARK: - Movie Details Cache Operations
    
    /// Saves movie details to local cache
    /// - Parameter movieDetails: Movie details to cache
    /// - Returns: Publisher that completes when save is done
    public func saveMovieDetails(_ movieDetails: MovieDetails) -> AnyPublisher<Void, Error> {
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SwiftDataError.operationFailed))
                return
            }
            
            Task {
                do {
                    try await self.swiftDataStack.performBackgroundTask { context in
                        // Check if movie details already exist
                        let movieId = movieDetails.id
                        let descriptor = FetchDescriptor<LocalMovieDetailsModel>(
                            predicate: #Predicate { $0.id == movieId }
                        )
                        
                        let existingDetails = try context.fetch(descriptor)
                        let localDetailsModel = existingDetails.first ?? LocalMovieDetailsModel(
                            id: movieDetails.id,
                            title: movieDetails.title,
                            overview: movieDetails.overview,
                            posterPath: movieDetails.posterPath,
                            backdropPath: movieDetails.backdropPath,
                            releaseDate: movieDetails.releaseDate,
                            voteAverage: movieDetails.voteAverage,
                            voteCount: movieDetails.voteCount,
                            originalLanguage: movieDetails.originalLanguage,
                            budget: movieDetails.budget,
                            revenue: movieDetails.revenue,
                            runtime: movieDetails.runtime,
                            status: movieDetails.status.rawValue,
                            tagline: movieDetails.tagline,
                            genres: [], //will be properly addeded in updateLocalMovieDetailsModel(detailsEntity:)
                            productionCompanies: [] //will be properly addeded in updateLocalMovieDetailsModel(detailsEntity:)
                        )
                        
                        // Update details model with latest data
                        self.updateLocalMovieDetailsModel(localDetailsModel, with: movieDetails)
                        
                        if existingDetails.isEmpty {
                            context.insert(localDetailsModel)
                        }
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .mapError { error in
            self.mapSwiftDatakError(error)
        }
        .eraseToAnyPublisher()
    }
    
    /// Gets cached movie details
    /// - Parameter movieId: Movie ID to retrieve
    /// - Returns: Publisher emitting cached movie details
    public func getCachedMovieDetails(movieId: Int) -> AnyPublisher<LocalMovieDetailsModel?, Error> {
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SwiftDataError.operationFailed))
                return
            }
            
            Task { @MainActor in
                do {
                    let expirationDate = Date().addingTimeInterval(-self.moviesCacheDuration)

                    let descriptor = FetchDescriptor<LocalMovieDetailsModel>(
                        predicate: #Predicate { $0.id == movieId && $0.updatededAt >= expirationDate }
                    )
                    
                    let detailsModels = try self.swiftDataStack.mainContext.fetch(descriptor)
                    
                    if let detailsModel = detailsModels.first {
                        promise(.success(detailsModel))
                    } else {
                        promise(.success(nil))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .mapError { error in
            self.mapSwiftDatakError(error)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helpers
    
    /// Updates movie details entity with domain data
    /// - Parameters:
    ///   - model: Movie model to update
    ///   - genre: Domain movie with new data
    private func updateLocalMovieDetailsModel(_ model: LocalMovieDetailsModel, with movieDetails: MovieDetails) {
        model.title = movieDetails.title
        model.overview = movieDetails.overview
        model.posterPath = movieDetails.posterPath
        model.backdropPath = movieDetails.backdropPath
        model.releaseDate = movieDetails.releaseDate
        model.voteAverage = movieDetails.voteAverage
        model.voteCount = movieDetails.voteCount
        model.originalLanguage = movieDetails.originalLanguage
        model.budget = movieDetails.budget
        model.revenue = movieDetails.revenue
        model.runtime = movieDetails.runtime
        model.status = movieDetails.status.rawValue
        model.tagline = movieDetails.tagline
        model.genres = movieDetails.genres.map {
            let localGenreModel = LocalGenreModel(
                id: $0.id,
                name: $0.name
            )
            updateLocalGenreModel(localGenreModel, with: $0)
            return localGenreModel
        }
        model.productionCompanies = movieDetails.productionCompanies.map {
            let localProductionCompanyModel = LocalProductionCompanyModel(
                id: $0.id,
                name: $0.name,
                logoPath: $0.logoPath
            )
            updateLocalProductionCompanyModel(localProductionCompanyModel, with: $0)
            return localProductionCompanyModel
        }
        
        model.updatededAt = Date()
    }
    
    /// Updates genre model with domain genre data
    /// - Parameters:
    ///   - model: Genre model to update
    ///   - genre: Domain genre with new data
    private func updateLocalGenreModel(_ model: LocalGenreModel, with genre: Genre) {
        model.name = genre.name
        model.updatededAt = Date()
    }
    
    /// Updates production company model with domain production company data
    /// - Parameters:
    ///   - model: Production company model to update
    ///   - productionCompany: Domain production company with new data
    private func updateLocalProductionCompanyModel(_ model: LocalProductionCompanyModel, with productionCompany: ProductionCompany) {
        model.name = productionCompany.name
        model.logoPath = productionCompany.logoPath
        model.updatededAt = Date()
    }
    
    /// Maps swiftData errors to local data source specific errors
    /// - Parameter error: Original swiftData error
    /// - Returns: Mapped local data source error
    private func mapSwiftDatakError(_ error: Error) -> LocalDataSourceError {
        if let swiftDataError = error as? MPCore.SwiftDataError {
            switch swiftDataError {
            case .operationFailed, .containerInitializationFailed:
                return .operationFailed
            case .saveFailed(let error):
                return .saveFailed(error)
            case .fetchFailed(let error):
                return .fetchFailed(error)
            case .deletionFailed(let error):
                return .deletionFailed(error)
            case .insertionFailed(let error):
                return .insertionFailed(error)
            case .modelNotFound, .invalidData:
                return .dataCorrupted
            }
        }
        return .unknown(error)
    }
}
