//
//  MovieListViewModel.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation
import Combine
import SwiftUI
import MPCore

/// ViewModel for the main movie list screen
/// Handles movie loading, pagination, search, filtering, and user interactions
/// Uses BaseViewModel for unified state management with tuple-based data model
public final class MovieListViewModel: BaseViewModel<(movies: [Movie], genres: [Genre])> {
    
    // MARK: - Published Properties
    
    /// Current view mode (grid or list)
    @Published public var viewMode: ViewMode = .grid
    
    /// Whether we can load more movies (pagination)
    @Published public var canLoadMore: Bool = true

    // MARK: - Published Properties - Search State

    /// Current search text
    @Published public var searchText: String = ""
        
    /// Whether we're currently searching
    @Published public var isSearching: Bool = false

    /// Recent search queries
    @Published public var recentSearches: [String] = []

    // MARK: - Data (Computed from BaseViewModel state)

    /// Current list of movies
    public var movies: [Movie] {
         data?.movies ?? []
     }
    
    /// Available genres for filtering
     public var genres: [Genre] {
         data?.genres ?? []
     }
    
    // MARK: - Dependencies
    
    private let repository: MovieRepositoryProtocol
    private let getGenresUseCase: GetGenresUseCase
    private let getMoviesUseCase: GetMoviesUseCase
    private let searchMoviesUseCase: SearchMoviesUseCase
    
    // MARK: - Private State
    
    private var currentPage: Int = 1
    private static let itemsPerPage = 20 // Assuming 20 items per page

    // MARK: - Initialization
    
    /// Initializes the ViewModel with required repository
    /// - Parameter repository: Repository for data access
    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
        self.getGenresUseCase = GetGenresUseCase(repository: repository)
        self.getMoviesUseCase = GetMoviesUseCase(repository: repository)
        self.searchMoviesUseCase = SearchMoviesUseCase(repository: repository)
        
        super.init()
        
        setupSearchBinding()
    }
    
    // MARK: - Public Methods - Data Loading
    
    /// Initial load of movies and genres
    public func loadInitialData() {
        setLoading()
        currentPage = 1

        Publishers.CombineLatest(
            getMoviesUseCase.execute(page: 1),
            getGenresUseCase.execute()
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.setFailure(error)
                }
            },
            receiveValue: { [weak self] movies, genres in
                self?.setSuccess((movies, genres))
                self?.canLoadMore = movies.count >= Self.itemsPerPage
            }
        )
        .store(in: &cancellables)
    }
    
    /// Refreshes all data
    public func refresh() {
        if isSearching {
            startSearch()
        } else {
            loadInitialData()
        }
    }
    
    /// Loads more movies for pagination (works for both normal and search modes)
    public func loadMore() {
        guard canLoadMore && !isLoadingMore && !isLoading else { return }
        
        currentPage += 1
        
        if isSearching && !searchText.isEmpty {
            performSearch(refresh: false)
        } else {
            loadMoreMovies()
        }
    }
    
    // MARK: - Public Methods - UI Actions

    /// Toggles view mode between grid and list
    public func toggleViewMode() {
        viewMode = viewMode == .grid ? .list : .grid
    }
    
    // MARK: - Public Methods - Search

    /// Starts a search with the current search text
    public func startSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            endSearch()
            return
        }
        
        isSearching = true
        currentPage = 1
        canLoadMore = true
        
        // Add to recent searches
        addToRecentSearches(searchText)
        
        performSearch(refresh: true)
    }
    
    /// Ends the current search and returns to regular movie list
    public func endSearch() {
        isSearching = false
        searchText = ""
        currentPage = 1
        canLoadMore = true
        refresh()
    }
    
    /// Performs a search with the given query
    /// - Parameter query: Search query to perform
    public func performSearch(with query: String) {
        searchText = query
        startSearch()
    }
    
    // MARK: - Private Methods - Data Loading

    /// Loads more movies for regular pagination
    private func loadMoreMovies() {
        setLoadingMore()
        getMoviesUseCase.execute(page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.setFailure(error)
                    }
                },
                receiveValue: { [weak self] newMovies in
                    guard let self = self else { return }
                    let currentMovies = self.movies
                    let combinedMovies = currentMovies + newMovies
                    
                    self.setSuccess((combinedMovies, self.genres))
                    self.canLoadMore = newMovies.count >= Self.itemsPerPage
                }
            )
            .store(in: &cancellables)
    }
    
    /// Performs search operation
    /// - Parameter refresh: Whether this is a new search (true) or pagination (false)
    private func performSearch(refresh: Bool) {
        let page = refresh ? 1 : currentPage
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if refresh {
            setLoading()
        } else {
            setLoadingMore()
        }
        
        searchMoviesUseCase.execute(query: query, page: page)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.setFailure(error)
                    }
                },
                receiveValue: { [weak self] searchResults in
                    guard let self = self else { return }
                    
                    let finalResults = refresh ? searchResults : self.movies + searchResults
                    self.setSuccess((finalResults, self.genres))
                    self.canLoadMore = searchResults.count >= Self.itemsPerPage
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods - Setup & Binding

    /// Sets up reactive search with debouncing
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                self.startSearch()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods - Utilities
    
    /// Adds query to recent searches with deduplication and limit
    /// - Parameter query: Search query to add
    private func addToRecentSearches(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Remove existing occurrence to avoid duplicates
        recentSearches.removeAll { $0 == trimmedQuery }
        
        // Add to beginning for most recent first
        recentSearches.insert(trimmedQuery, at: 0)
        
        // Limit to 10 recent searches
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
    }
}
