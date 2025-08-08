//
//  MovieLocalDataSourceIntegrationTests.swift
//  MPMoviesListing
//
//  Created by mac on 08/08/2025.
//

import XCTest
import Combine
import SwiftData
import MPCore
@testable import MPMoviesListing

/// Integration tests for MovieLocalDataSource using real SwiftDataStack
/// These tests verify the full integration with SwiftData persistence layer
final class MovieLocalDataSourceIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var dataSource: MovieLocalDataSource!
    private var testSwiftDataStack: SwiftDataStack!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory SwiftDataStack for integration testing
        // This provides real SwiftData functionality without persisting to disk
        do {
            testSwiftDataStack = try SwiftDataStack.forTesting(with: [
                LocalMovieModel.self,
                LocalGenreModel.self
            ])
            
            dataSource = MovieLocalDataSource(
                swiftDataStack: testSwiftDataStack,
                moviesCacheDuration: 3600, // 1 hour
                genresCacheDuration: 86400  // 24 hours
            )
            
            cancellables = Set<AnyCancellable>()
        } catch {
            XCTFail("Failed to set up test SwiftDataStack: \(error)")
        }
    }
    
    override func tearDown() {
        cancellables.removeAll()
        dataSource = nil
        testSwiftDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_withDefaultSwiftDataStack_initializesCorrectly() {
        // Arrange
        // Configure shared instance for test (this test verifies default initialization)
        do {
            SwiftDataStack.shared = try SwiftDataStack.forTesting(with: [LocalMovieModel.self, LocalGenreModel.self])
            
            // Act
            let defaultDataSource = MovieLocalDataSource()
            
            // Assert
            XCTAssertNotNil(defaultDataSource)
        } catch {
            XCTFail("Failed to configure shared SwiftDataStack: \(error)")
        }
    }
    
    func test_init_withCustomParameters_initializesCorrectly() {
        // Arrange
        let customMoviesDuration: TimeInterval = 7200 // 2 hours
        let customGenresDuration: TimeInterval = 172800 // 48 hours
        
        // Act
        let customDataSource = MovieLocalDataSource(
            swiftDataStack: testSwiftDataStack,
            moviesCacheDuration: customMoviesDuration,
            genresCacheDuration: customGenresDuration
        )
        
        // Assert
        XCTAssertNotNil(customDataSource)
    }
    
    // MARK: - Movie Save Operations Tests
    
    func test_saveMovies_withValidMovies_savesSuccessfully() async throws {
        // Arrange
        let movies = [Movie.sample, Movie.sample2]
        
        // Act
        _ = try await dataSource
            .saveMovies(movies)
            .values
            .first(where: { _ in true })
        
        // Assert
        try await MainActor.run {
            let savedMovies = try testSwiftDataStack.fetchAll(of: LocalMovieModel.self)
            XCTAssertEqual(savedMovies.count, movies.count)
        }
    }
    
    func test_saveMovies_withEmptyArray_completesSuccessfully() {
        // Arrange
        let emptyMovies: [Movie] = []
        let expectation = XCTestExpectation(description: "Empty save completes")
        
        var saveError: Error?
        
        // Act
        dataSource.saveMovies(emptyMovies)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        saveError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(saveError)
    }
    
    func test_saveMovies_withDuplicateMovies_updatesExistingMovies() async throws {
        // Arrange
        let originalMovie = Movie.sample
        let updatedMovie = Movie(
            id: originalMovie.id,
            title: "Updated Title",
            overview: "Updated Overview",
            posterPath: "/updated_poster.jpg",
            releaseDate: Date(),
            voteAverage: 9.5,
            genreIds: [35, 18]
        )
        
        // Act - Save original movie first
        _ = try await dataSource
            .saveMovies([originalMovie])
            .values
            .first(where: { _ in true })

        // Act - Save updated movie with same ID
        _ = try await dataSource
            .saveMovies([updatedMovie])
            .values
            .first(where: { _ in true })

        // Assert
        try await MainActor.run {
            let allMovies = try testSwiftDataStack.fetchAll(of: LocalMovieModel.self)
            XCTAssertEqual(allMovies.count, 1)
            XCTAssertEqual(allMovies.first?.title, "Updated Title")
            XCTAssertEqual(allMovies.first?.overview, "Updated Overview")
        }
    }
    
    // MARK: - Movie Fetch Operations Tests
    
    func test_getCachedMovies_withValidData_returnsCachedMovies() {
        // Arrange
        let movies = [Movie.sample, Movie.sample2]
        let saveExpectation = XCTestExpectation(description: "Movies saved")
        let fetchExpectation = XCTestExpectation(description: "Movies fetched")
        
        var cachedMovies: [LocalMovieModel]?
        var fetchError: Error?
        
        // First save movies
        dataSource.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Fetch cached movies
        dataSource.getCachedMovies(page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        fetchError = error
                    }
                    fetchExpectation.fulfill()
                },
                receiveValue: { movies in
                    cachedMovies = movies
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [fetchExpectation], timeout: 5.0)
        XCTAssertNil(fetchError)
        XCTAssertNotNil(cachedMovies)
        XCTAssertEqual(cachedMovies?.count, 2)
        XCTAssertTrue(cachedMovies?.contains { $0.id == Movie.sample.id } ?? false)
        XCTAssertTrue(cachedMovies?.contains { $0.id == Movie.sample2.id } ?? false)
    }
    
    func test_getCachedMovies_withEmptyCache_returnsEmptyArray() {
        // Arrange
        let expectation = XCTestExpectation(description: "Empty cache fetched")
        
        var cachedMovies: [LocalMovieModel]?
        var fetchError: Error?
        
        // Act - Fetch from empty cache
        dataSource.getCachedMovies(page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        fetchError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { movies in
                    cachedMovies = movies
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(fetchError)
        XCTAssertNotNil(cachedMovies)
        XCTAssertTrue(cachedMovies?.isEmpty ?? false)
    }
    
    func test_getCachedMovies_withPagination_returnsCorrectPage() {
        // Arrange - Create 25 movies (more than one page)
        let movies = (1...25).map { index in
            Movie(
                id: index,
                title: "Movie \(index)",
                overview: "Overview \(index)",
                posterPath: "/poster\(index).jpg",
                releaseDate: Date(),
                voteAverage: Double(index) / 5.0,
                genreIds: [28]
            )
        }
        
        let saveExpectation = XCTestExpectation(description: "Movies saved")
        let fetchPage1Expectation = XCTestExpectation(description: "Page 1 fetched")
        let fetchPage2Expectation = XCTestExpectation(description: "Page 2 fetched")
        
        var page1Movies: [LocalMovieModel]?
        var page2Movies: [LocalMovieModel]?
        
        // Save all movies
        dataSource.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Fetch page 1 (first 20 movies)
        dataSource.getCachedMovies(page: 1)
            .sink(
                receiveCompletion: { _ in fetchPage1Expectation.fulfill() },
                receiveValue: { movies in page1Movies = movies }
            )
            .store(in: &cancellables)
        
        wait(for: [fetchPage1Expectation], timeout: 5.0)
        
        // Act - Fetch page 2 (remaining 5 movies)
        dataSource.getCachedMovies(page: 2)
            .sink(
                receiveCompletion: { _ in fetchPage2Expectation.fulfill() },
                receiveValue: { movies in page2Movies = movies }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [fetchPage2Expectation], timeout: 5.0)
        XCTAssertEqual(page1Movies?.count, 20)
        XCTAssertEqual(page2Movies?.count, 5)
    }
    
    // MARK: - Genre Save Operations Tests
    
    func test_saveGenres_withValidGenres_savesSuccessfully() async throws {
        // Arrange
        let genres = [Genre.sample, Genre.sample2]
        
        // Act
        _ = try await dataSource
            .saveGenres(genres)
            .values
            .first(where: { _ in true })
        
        // Assert
        try await MainActor.run {
            let savedGenres = try testSwiftDataStack.fetchAll(of: LocalGenreModel.self)
            XCTAssertEqual(savedGenres.count, genres.count)
        }
    }
    
    func test_saveGenres_withDuplicateGenres_updatesExistingGenres() async throws {
        // Arrange
        let originalGenre = Genre.sample
        let updatedGenre = Genre(id: originalGenre.id, name: "Updated Genre")
        
        // Act - Save original genre first
        _ = try await dataSource
                .saveGenres([originalGenre])
                .values
                .first(where: { _ in true })
        
        // Act - Save updated genre with same ID
        _ = try await dataSource
            .saveGenres([updatedGenre])
            .values
            .first(where: { _ in true })
        
        // Assert
        try await MainActor.run {
            let allGenres = try testSwiftDataStack.fetchAll(of: LocalGenreModel.self)
            XCTAssertEqual(allGenres.count, 1)
            XCTAssertEqual(allGenres.first?.name, "Updated Genre")
        }
    }
    
    // MARK: - Genre Fetch Operations Tests
    
    func test_getCachedGenres_withValidData_returnsCachedGenres() {
        // Arrange
        let genres = [Genre.sample, Genre.sample2]
        let saveExpectation = XCTestExpectation(description: "Genres saved")
        let fetchExpectation = XCTestExpectation(description: "Genres fetched")
        
        var cachedGenres: [LocalGenreModel]?
        var fetchError: Error?
        
        // First save genres
        dataSource.saveGenres(genres)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Fetch cached genres
        dataSource.getCachedGenres()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        fetchError = error
                    }
                    fetchExpectation.fulfill()
                },
                receiveValue: { genres in
                    cachedGenres = genres
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [fetchExpectation], timeout: 5.0)
        XCTAssertNil(fetchError)
        XCTAssertNotNil(cachedGenres)
        XCTAssertEqual(cachedGenres?.count, 2)
        XCTAssertTrue(cachedGenres?.contains { $0.id == Genre.sample.id } ?? false)
        XCTAssertTrue(cachedGenres?.contains { $0.id == Genre.sample2.id } ?? false)
    }
    
    // MARK: - Search Operations Tests
    
    func test_searchMovies_withMatchingQuery_returnsMatchingMovies() {
        // Arrange
        let movies = [
            Movie(id: 1, title: "Action Hero", overview: "Action movie", posterPath: nil, releaseDate: Date(), voteAverage: 7.0, genreIds: [28]),
            Movie(id: 2, title: "Romantic Comedy", overview: "Romance movie", posterPath: nil, releaseDate: Date(), voteAverage: 6.0, genreIds: [35]),
            Movie(id: 3, title: "Action Adventure", overview: "Adventure movie", posterPath: nil, releaseDate: Date(), voteAverage: 8.0, genreIds: [28, 12])
        ]
        
        let saveExpectation = XCTestExpectation(description: "Movies saved")
        let searchExpectation = XCTestExpectation(description: "Movies searched")
        
        var searchResults: [LocalMovieModel]?
        
        // Save movies first
        dataSource.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Search for "Action"
        dataSource.searchMovies(query: "Action", page: 1)
            .sink(
                receiveCompletion: { _ in searchExpectation.fulfill() },
                receiveValue: { results in searchResults = results }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [searchExpectation], timeout: 5.0)
        XCTAssertNotNil(searchResults)
        XCTAssertEqual(searchResults?.count, 2) // "Action Hero" and "Action Adventure"
        XCTAssertTrue(searchResults?.allSatisfy { $0.title.contains("Action") } ?? false)
    }
    
    func test_searchMovies_withNoMatches_returnsEmptyArray() {
        // Arrange
        let movies = [Movie.sample]
        let saveExpectation = XCTestExpectation(description: "Movie saved")
        let searchExpectation = XCTestExpectation(description: "Movies searched")
        
        var searchResults: [LocalMovieModel]?
        
        // Save movie first
        dataSource.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Search for non-existent movie
        dataSource.searchMovies(query: "NonExistentMovie", page: 1)
            .sink(
                receiveCompletion: { _ in searchExpectation.fulfill() },
                receiveValue: { results in searchResults = results }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [searchExpectation], timeout: 5.0)
        XCTAssertNotNil(searchResults)
        XCTAssertTrue(searchResults?.isEmpty ?? false)
    }
    
    // MARK: - Filter and Sort Operations Tests
    
    func test_filterAndSortMovies_withGenreFilter_returnsFilteredMovies() {
        // Arrange
        let movies = [
            Movie(id: 1, title: "Action Movie", overview: "Action", posterPath: nil, releaseDate: Date(), voteAverage: 7.0, genreIds: [28]),
            Movie(id: 2, title: "Comedy Movie", overview: "Comedy", posterPath: nil, releaseDate: Date(), voteAverage: 6.0, genreIds: [35]),
            Movie(id: 3, title: "Action Comedy", overview: "Action Comedy", posterPath: nil, releaseDate: Date(), voteAverage: 8.0, genreIds: [28, 35])
        ]
        
        let saveExpectation = XCTestExpectation(description: "Movies saved")
        let filterExpectation = XCTestExpectation(description: "Movies filtered")
        
        var filteredResults: [LocalMovieModel]?
        
        // Save movies first
        dataSource.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Filter by Action genre (28)
        dataSource.filterAndSortMovies(genreIds: [28], sortOption: .popularity, page: 1)
            .sink(
                receiveCompletion: { _ in filterExpectation.fulfill() },
                receiveValue: { results in filteredResults = results }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [filterExpectation], timeout: 5.0)
        XCTAssertNotNil(filteredResults)
        XCTAssertEqual(filteredResults?.count, 2) // Action Movie and Action Comedy
        XCTAssertTrue(filteredResults?.allSatisfy { $0.genreIds.contains(28) } ?? false)
    }
    
    func test_filterAndSortMovies_withRatingSortOption_returnsSortedMovies() {
        // Arrange
        let movies = [
            Movie(id: 1, title: "Low Rating", overview: "Low", posterPath: nil, releaseDate: Date(), voteAverage: 5.0, genreIds: [28]),
            Movie(id: 2, title: "High Rating", overview: "High", posterPath: nil, releaseDate: Date(), voteAverage: 9.0, genreIds: [28]),
            Movie(id: 3, title: "Medium Rating", overview: "Medium", posterPath: nil, releaseDate: Date(), voteAverage: 7.0, genreIds: [28])
        ]
        
        let saveExpectation = XCTestExpectation(description: "Movies saved")
        let sortExpectation = XCTestExpectation(description: "Movies sorted")
        
        var sortedResults: [LocalMovieModel]?
        
        // Save movies first
        dataSource.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Sort by rating
        dataSource.filterAndSortMovies(genreIds: [], sortOption: .rating, page: 1)
            .sink(
                receiveCompletion: { _ in sortExpectation.fulfill() },
                receiveValue: { results in sortedResults = results }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [sortExpectation], timeout: 5.0)
        XCTAssertNotNil(sortedResults)
        XCTAssertEqual(sortedResults?.count, 3)
        
        // Verify sorted by rating (highest first)
        if let results = sortedResults {
            XCTAssertEqual(results[0].voteAverage, 9.0) // High Rating
            XCTAssertEqual(results[1].voteAverage, 7.0) // Medium Rating
            XCTAssertEqual(results[2].voteAverage, 5.0) // Low Rating
        }
    }
    
    func test_filterAndSortMovies_withTitleSortOption_returnsSortedMovies() {
        // Arrange
        let movies = [
            Movie(id: 1, title: "Zebra Movie", overview: "Z", posterPath: nil, releaseDate: Date(), voteAverage: 7.0, genreIds: [28]),
            Movie(id: 2, title: "Alpha Movie", overview: "A", posterPath: nil, releaseDate: Date(), voteAverage: 7.0, genreIds: [28]),
            Movie(id: 3, title: "Beta Movie", overview: "B", posterPath: nil, releaseDate: Date(), voteAverage: 7.0, genreIds: [28])
        ]
        
        let saveExpectation = XCTestExpectation(description: "Movies saved")
        let sortExpectation = XCTestExpectation(description: "Movies sorted by title")
        
        var sortedResults: [LocalMovieModel]?
        
        // Save movies first
        dataSource.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Sort by title
        dataSource.filterAndSortMovies(genreIds: [], sortOption: .title, page: 1)
            .sink(
                receiveCompletion: { _ in sortExpectation.fulfill() },
                receiveValue: { results in sortedResults = results }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [sortExpectation], timeout: 5.0)
        XCTAssertNotNil(sortedResults)
        XCTAssertEqual(sortedResults?.count, 3)
        
        // Verify sorted alphabetically
        if let results = sortedResults {
            XCTAssertEqual(results[0].title, "Alpha Movie")
            XCTAssertEqual(results[1].title, "Beta Movie")
            XCTAssertEqual(results[2].title, "Zebra Movie")
        }
    }
    
    // MARK: - Cache Expiration Tests
    
    func test_getCachedMovies_withExpiredCache_returnsEmptyResults() {
        // Arrange
        let shortCacheDuration: TimeInterval = 0.1 // 0.1 seconds
        let dataSourceWithShortCache = MovieLocalDataSource(
            swiftDataStack: testSwiftDataStack,
            moviesCacheDuration: shortCacheDuration,
            genresCacheDuration: 3600
        )
        
        let movies = [Movie.sample]
        let saveExpectation = XCTestExpectation(description: "Movie saved")
        let fetchExpectation = XCTestExpectation(description: "Expired cache fetched")
        
        var cachedMovies: [LocalMovieModel]?
        
        // Save movie first
        dataSourceWithShortCache.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Wait for cache to expire
        Thread.sleep(forTimeInterval: 0.2)
        
        // Act - Fetch from expired cache
        dataSourceWithShortCache.getCachedMovies(page: 1)
            .sink(
                receiveCompletion: { _ in fetchExpectation.fulfill() },
                receiveValue: { movies in cachedMovies = movies }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [fetchExpectation], timeout: 5.0)
        XCTAssertNotNil(cachedMovies)
        XCTAssertTrue(cachedMovies?.isEmpty ?? false)
    }
    
    // MARK: - Memory Management Tests
    
    func test_dataSource_deallocatesCorrectly() {
        // Arrange
        weak var weakDataSource = dataSource
        weak var weakSwiftDataStack = testSwiftDataStack
        
        // Act
        dataSource = nil
        testSwiftDataStack = nil
        
        // Assert - Check for potential retain cycles
        XCTAssertNil(weakDataSource)
        XCTAssertNil(weakSwiftDataStack)
    }
    
    func test_dataSource_withLongRunningOperations_managesMemoryCorrectly() {
        // Arrange
        let movies = (1...100).map { index in
            Movie(
                id: index,
                title: "Movie \(index)",
                overview: "Overview \(index)",
                posterPath: "/poster\(index).jpg",
                releaseDate: Date(),
                voteAverage: Double(index) / 10.0,
                genreIds: [28, 35]
            )
        }
        
        let expectation = XCTestExpectation(description: "Large save operation completed")
        
        // Act - Save large number of movies
        dataSource.saveMovies(movies)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 10.0)
        
        // Clean up
        cancellables.removeAll()
        XCTAssertTrue(cancellables.isEmpty)
    }
    
}

// MARK: - Sample Data Extensions

extension Movie {
    static let sample = Movie(
        id: 1,
        title: "Sample Movie",
        overview: "Sample overview",
        posterPath: "/sample_poster.jpg",
        releaseDate: Date(),
        voteAverage: 8.0,
        genreIds: [28, 12]
    )
    
    static let sample2 = Movie(
        id: 2,
        title: "Another Movie",
        overview: "Another overview",
        posterPath: "/another_poster.jpg",
        releaseDate: Date(),
        voteAverage: 7.5,
        genreIds: [35, 18]
    )
}

extension Genre {
    static let sample = Genre(id: 28, name: "Action")
    static let sample2 = Genre(id: 35, name: "Comedy")
}
