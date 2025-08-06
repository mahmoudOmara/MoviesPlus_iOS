//
//  MovieDetailsRepository.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import Combine
import MPCore

/// Repository implementation for movie details operations
/// Follows offline-first strategy with automatic caching
public final class MovieDetailsRepository: MovieDetailsRepositoryProtocol {
    
    // MARK: - Properties
    
    private let remoteDataSource: MovieDetailsRemoteDataSource
    private let localDataSource: MovieDetailsLocalDataSource
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    
    public init(
        remoteDataSource: MovieDetailsRemoteDataSource = MovieDetailsRemoteDataSource(),
        localDataSource: MovieDetailsLocalDataSource = MovieDetailsLocalDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    // MARK: - Movie Details Operations

    /// Fetches movie details with offline-first approach
    /// - Parameter movieId: movie ID to retrieve
    /// - Returns: Publisher emitting array of movies or error
    public func getMovieDetails(movieId: Int) -> AnyPublisher<MovieDetails?, Error> {
        remoteDataSource.getMovieDetails(movieId: movieId)
            .map { [weak self] in
                self?.movieDetailsModelToDomain($0)
            }
            .handleEvents(receiveOutput: { [weak self] movie in
                if let movie = movie {
                    self?.cacheMovieDetails(movie)
                }
            })
            .catch { [weak self] error -> AnyPublisher<MovieDetails?, Error> in
                // Fallback to cached data on network error
                guard let self = self else {
                    return Fail(error: self?.mapDataSourceError(error) ?? .unknown(error))
                        .eraseToAnyPublisher()
                }
                return self.localDataSource.getCachedMovieDetails(movieId: movieId)
                    .map { [weak self] in
                        if let movie = $0 {
                            return self?.movieLocalModelToDomain(movie)
                        }
                        return nil
                    }
                    .mapError { self.mapDataSourceError($0) }
                    .eraseToAnyPublisher()
            }
            .mapError { [weak self] error in
                self?.mapDataSourceError(error) ?? .unknown(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helpers
    
    /// Caches movie details in background
    /// - Parameters:
    ///   - movieDetails: Movie details to cache
    private func cacheMovieDetails(_ movieDetails: MovieDetails) {
        localDataSource.saveMovieDetails(movieDetails)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to cache movies: \(error)")
                }
            },
            receiveValue: { _ in
                // Movies cached successfully
            }
        )
        .store(in: &cancellables)
    }
    
    /// Converts network movie details model to domain movie details
    /// - Parameter model: Movie details model to convert
    /// - Returns: Domain movie details
    private func movieDetailsModelToDomain(_ model: MovieDetailsResponseModel) -> MovieDetails {
        return MovieDetails(
            id: model.id,
            title: model.title,
            overview: model.overview,
            posterPath: model.posterPath,
            backdropPath: model.backdropPath,
            releaseDate: model.releaseDate.flatMap { DateFormatter.apiDateFormatter.date(from: $0) },
            voteAverage: model.voteAverage,
            voteCount: model.voteCount,
            originalLanguage: model.originalLanguage,
            budget: model.budget,
            revenue: model.revenue,
            runtime: model.runtime,
            status: MovieStatus(rawValue: model.status) ?? .released,
            tagline: model.tagline,
            genres: model.genres.map({ genreModelToDomain($0) }),
            productionCompanies: model.productionCompanies.map({ productionCompanyModelToDomain($0) })
        )
    }
    
    /// Converts network genre model to domain genre
    /// - Parameter model: Genre model to convert
    /// - Returns: Domain Genre
    private func genreModelToDomain(_ model: GenreModel) -> Genre {
        return Genre(
            id: model.id,
            name: model.name
        )
    }
    
    /// Converts network production company model to domain production company
    /// - Parameter model: Production company model to convert
    /// - Returns: Domain production company
    private func productionCompanyModelToDomain(_ model: ProductionCompanyResponseModel) -> ProductionCompany {
        return ProductionCompany(
            id: model.id,
            name: model.name,
            logoPath: model.logoPath
        )
    }
    
    /// Converts local movie details model to domain movie details
    /// - Parameter model: Movie details model to convert
    /// - Returns: Domain movie details
    private func movieLocalModelToDomain(_ model: LocalMovieDetailsModel) -> MovieDetails {
        return MovieDetails(
            id: model.id,
            title: model.title,
            overview: model.overview,
            posterPath: model.posterPath,
            backdropPath: model.backdropPath,
            releaseDate: model.releaseDate,
            voteAverage: model.voteAverage,
            voteCount: model.voteCount,
            originalLanguage: model.originalLanguage,
            budget: model.budget,
            revenue: model.revenue,
            runtime: model.runtime,
            status: MovieStatus(rawValue: model.status) ?? .released,
            tagline: model.tagline,
            genres: model.genres.map({ genreLocalModelToDomain($0) }),
            productionCompanies: model.productionCompanies.map({ productionCompanyLocalModelToDomain($0) })
        )
    }
    
    /// Converts local genre model to domain genre
    /// - Parameter model: Genre model to convert
    /// - Returns: Domain genre
    private func genreLocalModelToDomain(_ model: LocalGenreModel) -> Genre {
        return Genre(
            id: model.id,
            name: model.name
        )
    }
    
    /// Converts local production company model to domain production company
    /// - Parameter model: Production company model to convert
    /// - Returns: Domain production company
    private func productionCompanyLocalModelToDomain(_ model: LocalProductionCompanyModel) -> ProductionCompany {
        return ProductionCompany(
            id: model.id,
            name: model.name,
            logoPath: model.logoPath
        )
    }
        
    /// Maps remote or local data source errors to repository specific errors
    /// - Parameter error: Original remote or local data source error
    /// - Returns: Mapped repository error
    private func mapDataSourceError(_ error: Error) -> RepositoryError {
        if let remoteDataSourceError = error as? RemoteDataSourceError {
            return .remote(remoteDataSourceError)
        }
        
        if let localDataSourceError = error as? LocalDataSourceError {
            return .local(localDataSourceError)
        }
        
        return .unknown(error)
    }

    
    // MARK: - Lifecycle
    
    deinit {
        cancellables.removeAll()
    }
}
