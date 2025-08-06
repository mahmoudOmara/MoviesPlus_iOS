//
//  MovieRepository.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation
import Combine
import MPCore

/// Concrete implementation of MovieRepositoryProtocol
/// Coordinates between remote and local data sources with offline-first approach
public final class MovieRepository: MovieRepositoryProtocol {
    
    // MARK: - Properties
    
    private let remoteDataSource: MovieRemoteDataSource
    private let localDataSource: MovieLocalDataSource
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    
    public init(
        remoteDataSource: MovieRemoteDataSource = MovieRemoteDataSource(),
        localDataSource: MovieLocalDataSource = MovieLocalDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    // MARK: - Movie Operations
    
    /// Fetches popular movies with offline-first approach
    /// - Parameter page: Page number for pagination (starting from 1)
    /// - Returns: Publisher emitting array of movies or error
    public func getPopularMovies(page: Int) -> AnyPublisher<[Movie], Error> {
        return remoteDataSource.getPopularMovies(page: page)
            .map { [weak self] response in
                response.results.compactMap { self?.movieModelToDomain($0) }
            }
            .handleEvents(receiveOutput: { [weak self] movies in
                // Cache movies in background
                self?.cacheMovies(movies)
            })
            .catch { [weak self] error -> AnyPublisher<[Movie], Error> in
                // Fallback to cached data on network error
                guard let self = self else {
                    return Fail(error: self?.mapDataSourceError(error) ?? .unknown(error))
                        .eraseToAnyPublisher()
                }
                return self.localDataSource.getCachedMovies(page: page)
                    .map { response in
                        response.compactMap { self.movieLocalModelToDomain($0) }
                    }
                    .mapError { self.mapDataSourceError($0) }
                    .eraseToAnyPublisher()
            }
            .mapError { [weak self] error in
                self?.mapDataSourceError(error) ?? .unknown(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Genre Operations
    
    /// Fetches all available movie genres with caching
    /// - Returns: Publisher emitting array of genres or error
    public func getGenres() -> AnyPublisher<[Genre], Error> {
        return remoteDataSource.getGenres()
            .map { [weak self] response in
                response.genres.compactMap { self?.genreModelToDomain($0) }
            }
            .handleEvents(receiveOutput: { [weak self] genres in
                // Cache genres in background
                self?.cacheGenres(genres)
            })
            .catch { [weak self] error -> AnyPublisher<[Genre], Error> in
                // Fallback to cached genres
                guard let self = self else {
                    return Fail(error: self?.mapDataSourceError(error) ?? .unknown(error))
                        .eraseToAnyPublisher()
                }
                return self.localDataSource.getCachedGenres()
                    .map { response in
                        response.compactMap { self.genreLocalModelToDomain($0) }
                    }
                    .mapError { self.mapDataSourceError($0) }
                    .eraseToAnyPublisher()
            }
            .mapError { [weak self] error in
                self?.mapDataSourceError(error) ?? .unknown(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Searches for movies by query text in the cached movies
    /// - Parameters:
    ///   - query: Search query text
    /// - Returns: Publisher emitting array of movies or error
    public func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        return localDataSource.searchMovies(query: query, page: page)
            .map { [weak self] response in
                response.compactMap { self?.movieLocalModelToDomain($0) }
            }
            .mapError { [weak self] error in
                self?.mapDataSourceError(error) ?? .unknown(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helpers
    
    /// Caches movies in background
    /// - Parameters:
    ///   - movies: Movies to cache
    private func cacheMovies(_ movies: [Movie]) {
        localDataSource.saveMovies(movies)
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
    
    /// Caches genres in background
    /// - Parameter genres: Genres to cache
    private func cacheGenres(_ genres: [Genre]) {
        localDataSource.saveGenres(genres)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to cache genres: \(error)")
                    }
                },
                receiveValue: { _ in
                    // Genres cached successfully
                }
            )
            .store(in: &cancellables)
    }
    
    /// Converts network movie model to domain movie
    /// - Parameter model: Movie model to convert
    /// - Returns: Domain movie
    private func movieModelToDomain(_ model: MovieModel) -> Movie {
        return Movie(
            id: model.id,
            title: model.title,
            overview: model.overview,
            posterPath: model.posterPath,
            releaseDate: model.releaseDate.flatMap { DateFormatter.apiDateFormatter.date(from: $0) },
            voteAverage: model.voteAverage,
            genreIds: model.genreIds
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
    
    /// Converts local movie model to domain movie
    /// - Parameter model: Movie model to convert
    /// - Returns: Domain movie
    private func movieLocalModelToDomain(_ model: LocalMovieModel) -> Movie {
        return Movie(
            id: model.id,
            title: model.title,
            overview: model.overview,
            posterPath: model.posterPath,
            releaseDate: model.releaseDate,
            voteAverage: model.voteAverage,
            genreIds: model.genreIds
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
