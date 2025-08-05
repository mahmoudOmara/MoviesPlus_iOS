//
//  MovieListView.swift
//  MPMoviesListing
//
//  Created by mac on 06/08/2025.
//


import SwiftUI

/// Main movie list view with grid/list toggle and search functionality
public struct MovieListView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var viewModel: MovieListViewModel
    @State private var showingSearch = false
    
    @Environment(\.theme) private var theme

    // MARK: - Grid Configuration
    
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160), spacing: theme.spacing.medium)]
    }
    
    // MARK: - Initialization
    
    public init(viewModel: MovieListViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            ZStack {
                theme.colors.background.ignoresSafeArea()
                
                contentView
            }
            .navigationTitle("Movies")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        viewModeToggle
                        searchButton
                    }
                }
            }
            .searchable(
                text: $viewModel.searchText,
                isPresented: $showingSearch,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search movies..."
            )
            .searchSuggestions {
                if showingSearch && !viewModel.recentSearches.isEmpty {
                    recentSearchSuggestions
                }
            }
            
            .refreshable {
                await refreshData()
            }
            .onAppear {
                if viewModel.movies.isEmpty {
                    viewModel.loadInitialData()
                }
            }
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            loadingView
            
        case .loading:
            if viewModel.movies.isEmpty {
                loadingView
            } else {
                moviesList
            }
            
        case .loadingMore, .success:
            if viewModel.movies.isEmpty {
                emptyStateView
            } else {
                moviesList
            }
            
        case .failure(let error):
            if viewModel.movies.isEmpty {
                errorView(error)
            } else {
                moviesList
            }
        }
    }
    
    private var moviesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.isSearching && !viewModel.searchText.isEmpty {
                    searchHeader
                }
                
                moviesGrid
                
                if viewModel.canLoadMore {
                    loadMoreButton
                }
            }
            .padding(.horizontal, theme.spacing.medium)
        }
        .background(theme.colors.background)
    }
    
    @ViewBuilder
    private var moviesGrid: some View {
        if viewModel.viewMode == .grid {
            LazyVGrid(columns: gridColumns, spacing: theme.spacing.medium) {
                ForEach(viewModel.movies, id: \.id) { movie in
                    MovieCellView(
                        movie: movie,
                        genres: [],
                        viewMode: .grid,
                        onTap: {
                            
                        }
                    )
                    .id(movie.id)
                    .onAppear {
                        if movie.id == viewModel.movies.last?.id {
                            viewModel.loadMore()
                        }
                    }
                }
            }
        } else {
            LazyVStack(spacing: theme.spacing.small) {
                ForEach(viewModel.movies, id: \.id) { movie in
                    MovieCellView(
                        movie: movie,
                        genres: [],
                        viewMode: .list,
                        onTap: {
                            
                        }
                    )
                    .id(movie.id)
                    .onAppear {
                        if movie.id == viewModel.movies.last?.id {
                            viewModel.loadMore()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header Views
    
    private var searchHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.small) {
                Text("Search Results")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.onBackground)
                
                Text("for \"\(viewModel.searchText)\"")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.onBackground)
            }
            
            Spacer()
            
            Button("Clear") {
                viewModel.endSearch()
            }
            .font(theme.typography.caption)
            .foregroundColor(theme.colors.accent)
        }
        .padding(.vertical, theme.spacing.medium)
    }
    
    
    // MARK: - State Views
    
    private var loadingView: some View {
        VStack(spacing: theme.spacing.large) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.accent))
            
            Text("Loading movies...")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.onBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.large) {
            Image(systemName: viewModel.isSearching ? "magnifyingglass" : "film")
                .font(.system(size: 64))
                .foregroundColor(theme.colors.onBackground)
            
            VStack(spacing: theme.spacing.small) {
                Text(viewModel.isSearching ? "No Results Found" : "No Movies Available")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.onBackground)
                
                Text(viewModel.isSearching ? 
                     "Try adjusting your search or filters" : 
                     "Pull to refresh or try again later")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.onBackground)
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.isSearching {
                Button("Clear Search") {
                    viewModel.endSearch()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(theme.spacing.large)
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: theme.spacing.large) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(theme.colors.error)
            
            VStack(spacing: theme.spacing.small) {
                Text("Something went wrong")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.onBackground)
                
                Text(error.localizedDescription)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.onBackground)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                viewModel.refresh()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(theme.spacing.large)
    }
    
    // MARK: - Toolbar Items
    
    private var searchButton: some View {
        Button(action: { showingSearch.toggle() }) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.accent)
        }
    }
    
    
    private var viewModeToggle: some View {
        Button(action: { viewModel.toggleViewMode() }) {
            Image(systemName: viewModel.viewMode.systemImage)
                .foregroundColor(theme.colors.accent)
        }
    }
    
    // MARK: - Load More
    
    private var loadMoreButton: some View {
        Group {
            if viewModel.isLoadingMore {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading more...")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.onBackground)
                }
                .padding(theme.spacing.medium)
            } else {
                Button("Load More") {
                    viewModel.loadMore()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(theme.spacing.medium)
            }
        }
    }
    
    // MARK: - Search Suggestions
    
    private var recentSearchSuggestions: some View {
        ForEach(viewModel.recentSearches, id: \.self) { query in
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(theme.colors.onBackground)
                
                Text(query)
                    .foregroundColor(theme.colors.onBackground)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.performSearch(with: query)
                showingSearch = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            viewModel.refresh()
            
            // Wait for the refresh to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Supporting Views


// MARK: - Button Styles

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, theme.spacing.large)
            .padding(.vertical, theme.spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: theme.layout.cornerRadius)
                    .fill(theme.colors.accent)
            )
            .foregroundColor(theme.colors.onSurface)
            .font(theme.typography.button)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(theme.animation.quick, value: configuration.isPressed)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, theme.spacing.large)
            .padding(.vertical, theme.spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: theme.layout.cornerRadius)
                    .stroke(theme.colors.accent, lineWidth: 1)
            )
            .foregroundColor(theme.colors.accent)
            .font(theme.typography.button)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(theme.animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct MovieListView_Previews: PreviewProvider {
    static var previews: some View {
        let repository = MovieRepository()
        let viewModel = MovieListViewModel(repository: repository)
        
        MovieListView(viewModel: viewModel)
            .preferredColorScheme(.light)
        
        MovieListView(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}
#endif
