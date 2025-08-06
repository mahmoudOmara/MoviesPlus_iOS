//
//  MovieLocalDataSource.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation
import Combine
import SwiftData
import MPCore

/// Local data source for managing cached movie data using SwiftData
/// Handles all local storage operations for the MovieList feature
public final class MovieLocalDataSource {
    
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
    
    // MARK: - Movie Cache Operations
    
    /// Saves movies to local cache
    /// - Parameters:
    ///   - movies: Movies to cache
    /// - Returns: Publisher that completes when save is done
    public func saveMovies(
        _ movies: [Movie],
    ) -> AnyPublisher<Void, Error> {
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(LocalDataSourceError.operationFailed))
                return
            }
            
            Task {
                do {
                    try await self.swiftDataStack.performBackgroundTask { context in
                        for movie in movies {
                            // Check if movie already exists
                            let movieId = movie.id
                            let descriptor = FetchDescriptor<LocalMovieModel>(
                                predicate: #Predicate { $0.id == movieId }
                            )
                            
                            let existingMovies = try context.fetch(descriptor)
                            let localMovieModel = existingMovies.first ?? LocalMovieModel(
                                id: movie.id,
                                title: movie.title,
                                overview: movie.overview,
                                posterPath: movie.posterURL,
                                releaseDate: movie.releaseDate,
                                voteAverage: movie.voteAverage,
                                genreIds: movie.genreIds
                            )
                            
                            // Update movie model with latest data
                            self.updateLocalMovieModel(localMovieModel, with: movie)
                            
                            if existingMovies.isEmpty {
                                context.insert(localMovieModel)
                            }
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
    
    /// Gets cached movies for a specific page
    /// - Parameter page: Page number to retrieve
    /// - Returns: Publisher emitting cached movies
    public func getCachedMovies(page: Int) -> AnyPublisher<[LocalMovieModel], Error> {
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(LocalDataSourceError.operationFailed))
                return
            }
            
            Task { @MainActor in
                do {
                    let pageSize = 20 // Standard TMDB page size
                    let offset = (page - 1) * pageSize
                    
                    let expirationDate = Date().addingTimeInterval(-self.moviesCacheDuration)

                    let descriptor = FetchDescriptor<LocalMovieModel>(
                        predicate: #Predicate { $0.updatededAt >= expirationDate },
                        sortBy: [SortDescriptor(\.createdAt, order: .forward)]
                    )
                    
                    let allMovies = try self.swiftDataStack.mainContext.fetch(descriptor)
                    
                    // Paginate results - basic pagination
                    let startIndex = min(offset, allMovies.count)
                    let endIndex = min(startIndex + pageSize, allMovies.count)
                    
                    guard startIndex < allMovies.count else {
                        promise(.success([]))
                        return
                    }
                    
                    let pageMovies = Array(allMovies[startIndex..<endIndex])
                    
                    promise(.success(pageMovies))
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
    
    // MARK: - Genre Cache Operations
    
    /// Saves genres to local cache
    /// - Parameter genres: Genres to cache
    /// - Returns: Publisher that completes when save is done
    public func saveGenres(_ genres: [Genre]) -> AnyPublisher<Void, Error> {
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(LocalDataSourceError.operationFailed))
                return
            }
            
            Task {
                do {
                    try await self.swiftDataStack.performBackgroundTask { context in
                        for genre in genres {
                            // Check if genre already exists
                            let genreId = genre.id
                            let descriptor = FetchDescriptor<LocalGenreModel>(
                                predicate: #Predicate { $0.id == genreId }
                            )
                            
                            let existingGenres = try context.fetch(descriptor)
                            let localGenreModel = existingGenres.first ?? LocalGenreModel(
                                id: genre.id,
                                name: genre.name
                            )
                            
                            // Update genre model with latest data
                            self.updateLocalGenreModel(localGenreModel, with: genre)
                            
                            if existingGenres.isEmpty {
                                context.insert(localGenreModel)
                            }
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
    
    /// Gets cached genres
    /// - Returns: Publisher emitting cached genres
    public func getCachedGenres() -> AnyPublisher<[LocalGenreModel], Error> {
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(LocalDataSourceError.operationFailed))
                return
            }
            
            Task { @MainActor in
                do {
                    let expirationDate = Date().addingTimeInterval(-self.genresCacheDuration)

                    let descriptor = FetchDescriptor<LocalGenreModel>(
                        predicate: #Predicate { $0.updatededAt >= expirationDate },
                        sortBy: [SortDescriptor(\.createdAt, order: .forward)]
                    )
                    
                    let allGenres = try self.swiftDataStack.mainContext.fetch(descriptor)

                    promise(.success(allGenres))
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
    
    // MARK: - Movie Cache Operations

    /// Searches cached movies by title with pagination
    /// - Parameters:
    ///   - query: The search query string
    ///   - page: The page number (starting from 1)
    /// - Returns: Publisher emitting matching movies
    public func searchMovies(
        query: String,
        page: Int
    ) -> AnyPublisher<[LocalMovieModel], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(LocalDataSourceError.operationFailed))
                return
            }
            
            Task { @MainActor in
                do {
                    let pageSize = 20 // Standard TMDB page size
                    let offset = (page - 1) * pageSize
                    let expirationDate = Date().addingTimeInterval(-self.moviesCacheDuration)
                    
                    let descriptor = FetchDescriptor<LocalMovieModel>(
                        predicate: #Predicate {
                            $0.updatededAt >= expirationDate &&
                            $0.title.localizedStandardContains(query)
                        },
                        sortBy: [SortDescriptor(\.createdAt, order: .forward)]
                    )
                    
                    let matchingMovies = try self.swiftDataStack.mainContext.fetch(descriptor)
                    
                    let startIndex = min(offset, matchingMovies.count)
                    let endIndex = min(startIndex + pageSize, matchingMovies.count)
                    
                    guard startIndex < matchingMovies.count else {
                        promise(.success([]))
                        return
                    }
                    
                    let pageMovies = Array(matchingMovies[startIndex..<endIndex])
                    promise(.success(pageMovies))
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
    
    /// Filters cached movies by genre IDs and sorts them according to the specified option
    /// - Parameters:
    ///   - genreIds: Array of genre IDs to filter by (empty array means no genre filter)
    ///   - sortOption: The sort option to apply
    ///   - page: The page number (starting from 1)
    /// - Returns: Publisher emitting filtered and sorted movies
    public func filterAndSortMovies(
        genreIds: [Int],
        sortOption: MovieSortOption,
        page: Int
    ) -> AnyPublisher<[LocalMovieModel], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(LocalDataSourceError.operationFailed))
                return
            }
            
            Task { @MainActor in
                do {
                    let pageSize = 20 // Standard TMDB page size
                    let offset = (page - 1) * pageSize
                    let expirationDate = Date().addingTimeInterval(-self.moviesCacheDuration)
                    
                    let descriptor = FetchDescriptor<LocalMovieModel>(
                        predicate: #Predicate { $0.updatededAt >= expirationDate },
                        sortBy: [SortDescriptor(\.createdAt, order: .forward)]
                    )
                    
                    let allMovies = try self.swiftDataStack.mainContext.fetch(descriptor)
                    
                    let filteredMovies = self.filterMovies(allMovies, by: genreIds)
                    
                    let sortedMovies = self.sortMovies(filteredMovies, by: sortOption)
                    
                    let startIndex = min(offset, sortedMovies.count)
                    let endIndex = min(startIndex + pageSize, sortedMovies.count)
                    
                    guard startIndex < sortedMovies.count else {
                        promise(.success([]))
                        return
                    }
                    
                    let pageMovies = Array(sortedMovies[startIndex..<endIndex])
                    promise(.success(pageMovies))
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
    
    /// Filter an array of movies using the specified genre ids
    /// - Parameters:
    ///   - movies: Array of movies to sort
    ///   - genreIds: Array of genre IDs to filter by (empty array means no genre filter)
    /// - Returns: Sorted array of movies
    private func filterMovies(_ movies: [LocalMovieModel], by genreIds: [Int]) -> [LocalMovieModel] {
        guard !genreIds.isEmpty else { return movies }
        return movies.filter { movie in
            return genreIds.allSatisfy { genreId in
                movie.genreIds.contains(genreId)
            }
        }
    }
    
    /// Sorts an array of movies based on the specified sort option
    /// - Parameters:
    ///   - movies: Array of movies to sort
    ///   - sortOption: The sort option to apply
    /// - Returns: Sorted array of movies
    private func sortMovies(_ movies: [LocalMovieModel], by sortOption: MovieSortOption) -> [LocalMovieModel] {
        switch sortOption {
        case .popularity:
            // For popularity, we'll keep the list as it is (default sort option)
            return movies
        case .rating:
            return movies.sorted { $0.voteAverage > $1.voteAverage }
        case .releaseDate:
            return movies.sorted { movie1, movie2 in
                guard let date1 = movie1.releaseDate, let date2 = movie2.releaseDate else {
                    // Put movies without release dates at the end
                    return movie1.releaseDate != nil && movie2.releaseDate == nil
                }
                return date1 > date2 // Most recent first
            }
        case .title:
            return movies.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }
    
    /// Updates movie model with domain movie data
    /// - Parameters:
    ///   - model: Movie model to update
    ///   - movie: Domain movie with new data
    private func updateLocalMovieModel(_ model: LocalMovieModel, with movie: Movie) {
        model.title = movie.title
        model.overview = movie.overview
        model.posterPath = movie.posterPath
        model.releaseDate = movie.releaseDate
        model.voteAverage = movie.voteAverage
        model.genreIds = movie.genreIds
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
