//
//  MovieDetailsLocalDataSourceTests.swift
//  MPMovieDetails
//
//  Created by mac on 08/08/2025.
//

import XCTest
import Combine
import SwiftData
import MPCore
@testable import MPMovieDetails

/// Integration tests for MovieDetailsLocalDataSource using real SwiftDataStack
/// These tests verify the full integration with SwiftData persistence layer
final class MovieDetailsLocalDataSourceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var dataSource: MovieDetailsLocalDataSource!
    private var testSwiftDataStack: SwiftDataStack!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory SwiftDataStack for integration testing
        // This provides real SwiftData functionality without persisting to disk
        do {
            testSwiftDataStack = try SwiftDataStack.forTesting(with: [
                LocalMovieDetailsModel.self,
                LocalGenreModel.self,
                LocalProductionCompanyModel.self
            ])
            
            dataSource = MovieDetailsLocalDataSource(
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
    
    func test_init_withDefaultParameters_setsPropertiesCorrectly() {
        // Arrange & Act
        let testDataSource = MovieDetailsLocalDataSource(
            swiftDataStack: testSwiftDataStack
        )
        
        // Assert
        XCTAssertNotNil(testDataSource)
    }
    
    func test_init_withCustomParameters_setsPropertiesCorrectly() {
        // Arrange & Act
        let testDataSource = MovieDetailsLocalDataSource(
            swiftDataStack: testSwiftDataStack,
            moviesCacheDuration: 7200,
            genresCacheDuration: 172800
        )
        
        // Assert
        XCTAssertNotNil(testDataSource)
    }
    
    // MARK: - Save Movie Details Tests
    
    func test_saveMovieDetails_withValidMovie_savesSuccessfully() {
        // Arrange
        let movieDetails = MovieDetails.sampleFightClub
        let expectation = XCTestExpectation(description: "Movie details saved successfully")
        
        // Act
        dataSource.saveMovieDetails(movieDetails)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to save valid movie details: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    // Save completed successfully
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        
        // Verify data was saved by attempting to retrieve it
        let retrieveExpectation = XCTestExpectation(description: "Movie details retrieved after save")
        
        dataSource.getCachedMovieDetails(movieId: movieDetails.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to retrieve saved movie details: \(error)")
                    }
                    retrieveExpectation.fulfill()
                },
                receiveValue: { savedMovieDetails in
                    XCTAssertNotNil(savedMovieDetails)
                    XCTAssertEqual(savedMovieDetails?.id, movieDetails.id)
                    XCTAssertEqual(savedMovieDetails?.title, movieDetails.title)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [retrieveExpectation], timeout: 5.0)
    }
    
    func test_saveMovieDetails_withComplexMovieData_savesAllFields() {
        // Arrange
        let movieDetails = MovieDetails.sampleInception
        let expectation = XCTestExpectation(description: "Complex movie details saved")
        
        // Act
        dataSource.saveMovieDetails(movieDetails)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to save complex movie details: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        
        // Verify all fields were saved correctly
        let retrieveExpectation = XCTestExpectation(description: "Complex movie details retrieved")
        
        dataSource.getCachedMovieDetails(movieId: movieDetails.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to retrieve complex movie details: \(error)")
                    }
                    retrieveExpectation.fulfill()
                },
                receiveValue: { savedMovieDetails in
                    XCTAssertNotNil(savedMovieDetails)
                    XCTAssertEqual(savedMovieDetails?.id, movieDetails.id)
                    XCTAssertEqual(savedMovieDetails?.title, movieDetails.title)
                    XCTAssertEqual(savedMovieDetails?.overview, movieDetails.overview)
                    XCTAssertEqual(savedMovieDetails?.budget, movieDetails.budget)
                    XCTAssertEqual(savedMovieDetails?.revenue, movieDetails.revenue)
                    XCTAssertEqual(savedMovieDetails?.runtime, movieDetails.runtime)
                    XCTAssertEqual(savedMovieDetails?.genres.count, movieDetails.genres.count)
                    XCTAssertEqual(savedMovieDetails?.productionCompanies.count, movieDetails.productionCompanies.count)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [retrieveExpectation], timeout: 5.0)
    }
    
    func test_saveMovieDetails_updatingExistingMovie_replacesData() {
        // Arrange
        let originalMovieDetails = MovieDetails.sampleFightClub
        let updatedMovieDetails = MovieDetails(
            id: originalMovieDetails.id,
            title: "Fight Club - Updated",
            overview: "Updated overview",
            voteAverage: 9.0,
            voteCount: 30000,
            originalLanguage: "en",
            budget: 70000000,
            revenue: 120000000
        )
        
        let saveOriginalExpectation = XCTestExpectation(description: "Original movie saved")
        let saveUpdatedExpectation = XCTestExpectation(description: "Updated movie saved")
        
        // Act - Save original movie first
        dataSource.saveMovieDetails(originalMovieDetails)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to save original movie: \(error)")
                    }
                    saveOriginalExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveOriginalExpectation], timeout: 5.0)
        
        // Save updated movie with same ID
        dataSource.saveMovieDetails(updatedMovieDetails)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to update movie: \(error)")
                    }
                    saveUpdatedExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveUpdatedExpectation], timeout: 5.0)
        
        // Verify the updated data was saved
        let retrieveExpectation = XCTestExpectation(description: "Updated movie retrieved")
        
        dataSource.getCachedMovieDetails(movieId: originalMovieDetails.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to retrieve updated movie: \(error)")
                    }
                    retrieveExpectation.fulfill()
                },
                receiveValue: { savedMovieDetails in
                    XCTAssertNotNil(savedMovieDetails)
                    XCTAssertEqual(savedMovieDetails?.title, updatedMovieDetails.title)
                    XCTAssertEqual(savedMovieDetails?.overview, updatedMovieDetails.overview)
                    XCTAssertEqual(savedMovieDetails?.budget, updatedMovieDetails.budget)
                    XCTAssertEqual(savedMovieDetails?.revenue, updatedMovieDetails.revenue)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [retrieveExpectation], timeout: 5.0)
    }
    
    // MARK: - Get Cached Movie Details Tests
    
    func test_getCachedMovieDetails_withNonExistentMovie_returnsNil() {
        // Arrange
        let nonExistentMovieId = 99999
        let expectation = XCTestExpectation(description: "Non-existent movie returns nil")
        
        // Act
        dataSource.getCachedMovieDetails(movieId: nonExistentMovieId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail for non-existent movie: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { movieDetails in
                    XCTAssertNil(movieDetails, "Should return nil for non-existent movie")
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_getCachedMovieDetails_withValidCachedMovie_returnsMovieDetails() {
        // Arrange
        let movieDetails = MovieDetails.sampleFightClub
        let saveExpectation = XCTestExpectation(description: "Movie saved for retrieval test")
        let retrieveExpectation = XCTestExpectation(description: "Movie retrieved successfully")
        
        // First save a movie
        dataSource.saveMovieDetails(movieDetails)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to save movie for retrieval test: \(error)")
                    }
                    saveExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Act - Retrieve the movie
        dataSource.getCachedMovieDetails(movieId: movieDetails.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to retrieve cached movie: \(error)")
                    }
                    retrieveExpectation.fulfill()
                },
                receiveValue: { cachedMovieDetails in
                    XCTAssertNotNil(cachedMovieDetails)
                    XCTAssertEqual(cachedMovieDetails?.id, movieDetails.id)
                    XCTAssertEqual(cachedMovieDetails?.title, movieDetails.title)
                    XCTAssertEqual(cachedMovieDetails?.overview, movieDetails.overview)
                }
            )
            .store(in: &cancellables)
        
        // Assert
        wait(for: [retrieveExpectation], timeout: 5.0)
    }
    
    func test_getCachedMovieDetails_withExpiredCache_returnsNil() {
        // Arrange
        let movieDetails = MovieDetails.sampleFightClub
        let shortCacheDuration: TimeInterval = 0.1 // 0.1 seconds
        
        let shortCacheDataSource = MovieDetailsLocalDataSource(
            swiftDataStack: testSwiftDataStack,
            moviesCacheDuration: shortCacheDuration,
            genresCacheDuration: 86400
        )
        
        let saveExpectation = XCTestExpectation(description: "Movie saved with short cache")
        let retrieveExpectation = XCTestExpectation(description: "Expired movie returns nil")
        
        // Save movie with short cache duration
        shortCacheDataSource.saveMovieDetails(movieDetails)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to save movie with short cache: \(error)")
                    }
                    saveExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Wait for cache to expire
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Act - Try to retrieve expired movie
            shortCacheDataSource.getCachedMovieDetails(movieId: movieDetails.id)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            XCTFail("Should not fail for expired cache: \(error)")
                        }
                        retrieveExpectation.fulfill()
                    },
                    receiveValue: { expiredMovieDetails in
                        XCTAssertNil(expiredMovieDetails, "Should return nil for expired cache")
                    }
                )
                .store(in: &self.cancellables)
        }
        
        // Assert
        wait(for: [retrieveExpectation], timeout: 10.0)
    }
    
    // MARK: - Data Integrity Tests
    
    func test_saveMovieDetails_withCompleteGenresAndCompanies_preservesRelationships() {
        // Arrange
        let movieDetails = MovieDetails.sampleInception // Has multiple genres and companies
        let saveExpectation = XCTestExpectation(description: "Movie with relationships saved")
        let retrieveExpectation = XCTestExpectation(description: "Movie with relationships retrieved")
        
        // Act - Save movie with complex relationships
        dataSource.saveMovieDetails(movieDetails)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to save movie with relationships: \(error)")
                    }
                    saveExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Retrieve and verify relationships are preserved
        dataSource.getCachedMovieDetails(movieId: movieDetails.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Should not fail to retrieve movie with relationships: \(error)")
                    }
                    retrieveExpectation.fulfill()
                },
                receiveValue: { savedMovieDetails in
                    XCTAssertNotNil(savedMovieDetails)
                    
                    // Verify genres are preserved
                    XCTAssertEqual(savedMovieDetails?.genres.count, movieDetails.genres.count)
                    
                    let savedGenreIDs = Set(savedMovieDetails?.genres.map { $0.id } ?? [])
                    let originalGenreIDs = Set(movieDetails.genres.map { $0.id })
                    XCTAssertEqual(savedGenreIDs, originalGenreIDs)

                    // Verify production companies are preserved
                    XCTAssertEqual(savedMovieDetails?.productionCompanies.count, movieDetails.productionCompanies.count)
                    
                    let savedCompaniesIDs = Set(savedMovieDetails?.productionCompanies.map { $0.id } ?? [])
                    let originalCompaniesIDs = Set(movieDetails.productionCompanies.map { $0.id })
                    XCTAssertEqual(savedCompaniesIDs, originalCompaniesIDs)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [retrieveExpectation], timeout: 5.0)
    }
}
