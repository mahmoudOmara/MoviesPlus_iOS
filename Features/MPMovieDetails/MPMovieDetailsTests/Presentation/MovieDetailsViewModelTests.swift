//
//  MovieDetailsViewModelTests.swift
//  MPMovieDetails
//
//  Created by mac on 08/08/2025.
//


import XCTest
import Combine
import SwiftUI
import MPCore
@testable import MPMovieDetails

/// Unit tests for MovieDetailsViewModel with mocked dependencies
final class MovieDetailsViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var viewModel: MovieDetailsViewModel!
    private var mockRepository: MockMovieDetailsRepository!
    private var mockSharingService: MockSharingService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockMovieDetailsRepository()
        mockSharingService = MockSharingService()
        cancellables = Set<AnyCancellable>()
        
        // Create view model with mocked dependencies
        viewModel = MovieDetailsViewModel(
            movieId: 550,
            repository: mockRepository,
            sharingService: mockSharingService
        )
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockRepository = nil
        mockSharingService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_withValidMovieId_setsPropertiesCorrectly() {
        // Arrange
        let movieId = 123
        let testRepository = MockMovieDetailsRepository()
        let testSharingService = MockSharingService()
        
        // Act
        let testViewModel = MovieDetailsViewModel(
            movieId: movieId,
            repository: testRepository,
            coordinator: nil,
            sharingService: testSharingService
        )
        
        // Assert
        XCTAssertNotNil(testViewModel)
        XCTAssertEqual(testViewModel.selectedTab, .overview)
        XCTAssertFalse(testViewModel.showFullOverview)
        XCTAssertEqual(testViewModel.state, .idle)
    }
    
    // MARK: - Initial Data Loading Tests
    
    func test_loadInitialData_callsLoadMovieDetails() {
        // Arrange
        mockRepository.getMovieDetailsResult = .success(MovieDetails.sampleFightClub)
        
        let expectation = XCTestExpectation(description: "Initial data loading completed")
        
        // Observe state changes
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadInitialData()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(mockRepository.getMovieDetailsCalled)
        XCTAssertEqual(mockRepository.lastMovieId, 550)
    }
    
    func test_loadMovieDetails_withValidMovieId_setsSuccessState() {
        // Arrange
        let expectedMovieDetails = MovieDetails.sampleFightClub
        mockRepository.getMovieDetailsResult = .success(expectedMovieDetails)
        
        let expectation = XCTestExpectation(description: "Movie details loaded successfully")
        
        // Observe state changes
        viewModel.$state
            .sink { state in
                if case .success(let movieDetails) = state {
                    XCTAssertEqual(movieDetails.id, expectedMovieDetails.id)
                    XCTAssertEqual(movieDetails.title, expectedMovieDetails.title)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadMovieDetails()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasError)
    }
    
    func test_loadMovieDetails_withRepositoryError_setsFailureState() {
        // Arrange
        let repositoryError = RepositoryError.remote(.networkUnavailable)
        mockRepository.getMovieDetailsResult = .failure(repositoryError)
        
        let expectation = XCTestExpectation(description: "Movie details loading failed")
        
        // Observe state changes
        viewModel.$state
            .sink { state in
                if case .failure(let error) = state {
                    XCTAssertTrue(error is RepositoryError)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadMovieDetails()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(viewModel.hasError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_loadMovieDetails_setsLoadingStateDuringExecution() {
        // Arrange
        mockRepository.getMovieDetailsResult = .success(MovieDetails.sampleFightClub)
        
        var stateChanges: [ViewModelState<MovieDetails>] = []
        let expectation = XCTestExpectation(description: "Loading state observed")
        
        // Observe all state changes
        viewModel.$state
            .sink { state in
                stateChanges.append(state)
                if stateChanges.count >= 3 { // idle -> loading -> success
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadMovieDetails()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(stateChanges[0], .idle)
        XCTAssertEqual(stateChanges[1], .loading)
        XCTAssertTrue(stateChanges[2].isSuccess)
    }
    
    // MARK: - Tab Management Tests
    
    func test_selectTab_changesSelectedTab() {
        // Arrange
        let newTab = MovieDetailsSection.cast
        
        // Act
        viewModel.selectTab(newTab)
        
        // Assert
        XCTAssertEqual(viewModel.selectedTab, newTab)
    }
    
    func test_selectTab_withAllTabOptions_setsCorrectTab() {
        // Arrange & Act & Assert
        let allTabs: [MovieDetailsSection] = [.overview, .cast, .reviews, .similar]
        
        for tab in allTabs {
            viewModel.selectTab(tab)
            XCTAssertEqual(viewModel.selectedTab, tab)
        }
    }
    
    func test_selectTab_overview_doesNotTriggerAdditionalLoading() {
        // Arrange
        mockRepository.reset() // Clear any previous calls
        
        // Act
        viewModel.selectTab(.overview)
        
        // Assert
        XCTAssertFalse(mockRepository.getMovieDetailsCalled)
    }
    
    // MARK: - UI State Management Tests
    
    func test_toggleFullOverview_changesShowFullOverview() {
        // Arrange
        let initialState = viewModel.showFullOverview
        
        // Act
        viewModel.toggleFullOverview()
        
        // Assert
        XCTAssertNotEqual(viewModel.showFullOverview, initialState)
    }
    
    func test_toggleFullOverview_multipleCalls_togglesCorrectly() {
        // Arrange
        let initialState = viewModel.showFullOverview
        
        // Act & Assert
        viewModel.toggleFullOverview()
        XCTAssertEqual(viewModel.showFullOverview, !initialState)
        
        viewModel.toggleFullOverview()
        XCTAssertEqual(viewModel.showFullOverview, initialState)
        
        viewModel.toggleFullOverview()
        XCTAssertEqual(viewModel.showFullOverview, !initialState)
    }
    
    // MARK: - Sharing Service Integration Tests
    
    func test_shareMovie_withValidMovieData_callsSharingService() {
        // Arrange
        let movieDetails = MovieDetails.sampleFightClub
        mockRepository.getMovieDetailsResult = .success(movieDetails)
        
        let loadExpectation = XCTestExpectation(description: "Movie data loaded")
        
        // First load movie data
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .success = state {
                    loadExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadMovieDetails()
        wait(for: [loadExpectation], timeout: 5.0)
        
        // Act
        viewModel.shareMovie()
        
        // Assert
        XCTAssertTrue(mockSharingService.shareMovieCalled)
        XCTAssertEqual(mockSharingService.lastTitle, movieDetails.title)
        XCTAssertEqual(mockSharingService.lastMovieId, movieDetails.id)
        XCTAssertNil(mockSharingService.lastSourceView)
    }
    
    func test_shareMovie_withFailedLoad_doesNotCallSharingService() {
        // Arrange
        mockRepository.getMovieDetailsResult = .failure(RepositoryError.remote(.networkUnavailable))
        
        let errorExpectation = XCTestExpectation(description: "Movie loading failed")
        
        viewModel.$state
            .sink { state in
                if case .failure = state {
                    errorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadMovieDetails()
        wait(for: [errorExpectation], timeout: 5.0)
        
        // Act
        viewModel.shareMovie()
        
        // Assert
        XCTAssertFalse(mockSharingService.shareMovieCalled)
    }
    
    // MARK: - Refresh and Retry Tests
    
    func test_refresh_callsLoadInitialData() {
        // Arrange
        mockRepository.getMovieDetailsResult = .success(MovieDetails.sampleFightClub)
        
        let expectation = XCTestExpectation(description: "Refresh completed")
        
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.refresh()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(mockRepository.getMovieDetailsCalled)
    }
    
    func test_retry_callsLoadMovieDetails() {
        // Arrange
        mockRepository.getMovieDetailsResult = .success(MovieDetails.sampleInception)
        
        let expectation = XCTestExpectation(description: "Retry completed")
        
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.retry()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(mockRepository.getMovieDetailsCalled)
    }
    
    // MARK: - State Property Tests
    
    func test_dataProperty_returnsCorrectData() {
        // Arrange
        let expectedMovieDetails = MovieDetails.sampleFightClub
        mockRepository.getMovieDetailsResult = .success(expectedMovieDetails)
        
        let expectation = XCTestExpectation(description: "Data property updated")
        
        viewModel.$state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadMovieDetails()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(viewModel.data)
        XCTAssertEqual(viewModel.data?.id, expectedMovieDetails.id)
        XCTAssertEqual(viewModel.data?.title, expectedMovieDetails.title)
    }
    
    func test_errorProperty_returnsCorrectError() {
        // Arrange
        let expectedError = RepositoryError.remote(.networkUnavailable)
        mockRepository.getMovieDetailsResult = .failure(expectedError)
        
        let expectation = XCTestExpectation(description: "Error property updated")
        
        viewModel.$state
            .sink { state in
                if case .failure = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        viewModel.loadMovieDetails()
        
        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error is RepositoryError)
    }
        
    // MARK: - Memory Management Tests
    
    func test_viewModel_properlyReleasesResources() {
        // Arrange
        weak var weakViewModel: MovieDetailsViewModel?
        
        do {
            let testViewModel = MovieDetailsViewModel(
                movieId: 123,
                repository: MockMovieDetailsRepository(),
                coordinator: nil,
                sharingService: MockSharingService()
            )
            
            weakViewModel = testViewModel
            
            // Use the view model
            testViewModel.loadMovieDetails()
        }
        
        // Act & Assert
        XCTAssertNil(weakViewModel)
    }
}

// MARK: - Mock Sharing Service

class MockSharingService: SharingServiceProtocol {
    
    // MARK: - Mock Properties
    
    var shareMovieCalled = false
    var lastTitle: String?
    var lastMovieId: Int?
    var lastSourceView: UIView?
    
    // MARK: - SharingServiceProtocol Implementation
    
    func shareMovie(title: String, movieId: Int, sourceView: UIView?) {
        shareMovieCalled = true
        lastTitle = title
        lastMovieId = movieId
        lastSourceView = sourceView
    }
    
    // MARK: - Mock Reset Methods
    
    func reset() {
        shareMovieCalled = false
        lastTitle = nil
        lastMovieId = nil
        lastSourceView = nil
    }
}
