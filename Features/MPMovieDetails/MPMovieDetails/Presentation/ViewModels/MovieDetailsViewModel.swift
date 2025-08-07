//
//  MovieDetailsViewModel.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import SwiftUI
import Combine
import MPCore

/// ViewModel for the movie details screen
/// Manages movie details, credits, reviews, and user interactions
public final class MovieDetailsViewModel: BaseViewModel<MovieDetails> {
    
    // MARK: - Published Properties
    
    /// Currently selected tab
    @Published public var selectedTab: MovieDetailsSection = .overview
    
    /// Show full overview text
    @Published public var showFullOverview: Bool = false
    
    // MARK: - Dependencies
    
    private let movieId: Int
    private let repository: MovieDetailsRepositoryProtocol
    private let getMovieDetailsUseCase: GetMovieDetailsUseCase
    private let sharingService: SharingServiceProtocol

    // MARK: - Initialization
    
    public init(
        movieId: Int,
        repository: MovieDetailsRepositoryProtocol,
        sharingService: SharingServiceProtocol
    ) {
        self.movieId = movieId
        self.repository = repository
        self.getMovieDetailsUseCase = GetMovieDetailsUseCase(repository: repository)
        self.sharingService = sharingService
    }
    
    // MARK: - Data Loading Methods
    
    /// Loads initial movie data (details, credits, and favorite status)
    public func loadInitialData() {
        loadMovieDetails()
    }
    
    /// Loads movie details
    public func loadMovieDetails() {
        setLoading()
        getMovieDetailsUseCase.execute(movieId: movieId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.setFailure(error)
                    }
                },
                receiveValue: { [weak self] movieDetails in
                    self?.setSuccess(movieDetails)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - User Actions
    
    /// Refreshes all data
    public func refresh() {
        loadInitialData()
    }
    
    /// Shares the current movie using the sharing service
    public func shareMovie() {
        
    }
    
    /// Retries failed operations
    public func retry() {
        loadMovieDetails()
    }
    
    // MARK: - Tab Management
    
    /// Changes the selected tab
    /// - Parameter tab: Tab to select
    public func selectTab(_ tab: MovieDetailsSection) {
        selectedTab = tab
        
        // Load data for tab if needed
        switch tab {
        case .overview:
            break // Already loaded
        case .cast:
            break // Coming soon
        case .reviews:
            break // Coming soon
        case .similar:
            break // Coming soon
        }
    }
    
    // MARK: - UI State Management
    
    /// Toggles full overview visibility
    public func toggleFullOverview() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showFullOverview.toggle()
        }
    }
}
