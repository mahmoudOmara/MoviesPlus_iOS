//
//  MovieDetailsView.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import SwiftUI
import MPCore

/// Main movie details view displaying comprehensive movie information
public struct MovieDetailsView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var viewModel: MovieDetailsViewModel
    @Environment(\.theme) private var theme
    
    // MARK: - Initialization
    
    public init(viewModel: MovieDetailsViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            ZStack {
                theme.colors.background.ignoresSafeArea()
                
                contentView
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadInitialData()
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
            loadingView
            
        case .success(let movieDetails):
            movieDetailsContent(movieDetails)
            
        case .failure(let error):
            errorView(error)
            
        case .loadingMore:
            // This shouldn't happen for movie details, but handle gracefully
            if let movieDetails = viewModel.data {
                movieDetailsContent(movieDetails)
            } else {
                loadingView
            }
        }
    }
    
    private func movieDetailsContent(_ movieDetails: MovieDetails) -> some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Hero section with backdrop and poster
                    heroSection(geometry: geometry, movieDetails: movieDetails)
                    
                    // Main content
                    contentSection(movieDetails: movieDetails)
                }
            }
            .ignoresSafeArea(.container, edges: .top)
        }
    }
    
    // MARK: - State Views
    
    private var loadingView: some View {
        VStack(spacing: theme.spacing.large) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.accent))
            
            Text("Loading movie details...")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.onBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                viewModel.retry()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(theme.spacing.large)
    }
    
    // MARK: - Hero Section
    
    private func heroSection(geometry: GeometryProxy, movieDetails: MovieDetails) -> some View {
        ZStack(alignment: .bottom) {
            // Backdrop image
            backdropImage(movieDetails: movieDetails)
                .frame(height: geometry.size.height * 0.6)
                .clipped()
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    .clear,
                    theme.colors.background.opacity(0.8),
                    theme.colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: geometry.size.height * 0.3)
            
            // Hero content
            heroContent(movieDetails: movieDetails)
                .padding(.horizontal, theme.spacing.medium)
                .padding(.bottom, theme.spacing.large)
        }
    }
    
    private func backdropImage(movieDetails: MovieDetails) -> some View {
        Group {
            if let backdropURL = movieDetails.backdropURL {
                ImageLoaderView(imageURLString: backdropURL, contentMode: .fill)
            } else {
                Rectangle()
                    .fill(theme.colors.surface)
            }
        }
    }
    
    private func heroContent(movieDetails: MovieDetails) -> some View {
        HStack(alignment: .bottom, spacing: theme.spacing.medium) {
            // Poster image
            posterImage(movieDetails: movieDetails)
                .frame(width: 120, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: theme.layout.cornerRadius))
                .shadow(
                    color: theme.layout.shadowColor,
                    radius: theme.layout.shadowRadius * 2,
                    x: theme.layout.shadowOffset.width,
                    y: theme.layout.shadowOffset.height
                )
            
            // Movie info
            VStack(alignment: .leading, spacing: theme.spacing.small) {
                Spacer()
                
                // Title and year
                movieTitleSection(movieDetails: movieDetails)
                
                // Rating and runtime
                movieMetaSection(movieDetails: movieDetails)
                
                // Action buttons
                actionButtons
            }
            
            Spacer()
        }
    }
    
    private func posterImage(movieDetails: MovieDetails) -> some View {
        Group {
            if let posterURL = movieDetails.posterURL {
                ImageLoaderView(imageURLString: posterURL, contentMode: .fill)
            } else {
                ZStack {
                    Rectangle()
                        .fill(theme.colors.surface)
                    
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(theme.colors.onSurface)
                }
            }
        }
    }
    
    private func movieTitleSection(movieDetails: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
            Text(movieDetails.title)
                .font(theme.typography.title3)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.onBackground)
                .lineLimit(2)
            
            if let releaseYear = movieDetails.releaseYear {
                Text(releaseYear)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.onSurface)
            }
            
            if let tagline = movieDetails.tagline, !tagline.isEmpty {
                Text(tagline)
                    .font(theme.typography.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(2)
            }
        }
    }
    
    private func movieMetaSection(movieDetails: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
            HStack(spacing: theme.spacing.small) {
                // Rating
                HStack(spacing: theme.spacing.xSmall) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(theme.colors.warning)
                    
                    Text(movieDetails.formattedVoteAverage)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.onSurface)
                }
                
                // Runtime
                if let runtime = movieDetails.formattedRuntime {
                    Text("•")
                        .foregroundColor(theme.colors.onSurface)
                    
                    Text(runtime)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.onSurface)
                }
                
                // Status
                Text("•")
                    .foregroundColor(theme.colors.onSurface)
                
                Text(movieDetails.status.displayName)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.onSurface)
            }
            
            // Genres
            if !movieDetails.genres.isEmpty {
                Text(movieDetails.genreNames)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.onSurface)
                    .lineLimit(2)
            }
        }
    }
    
    private var actionButtons: some View {
        // Share button
        Button(action: viewModel.shareMovie) {
            HStack(spacing: theme.spacing.xSmall) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                
                Text("Share")
                    .font(theme.typography.caption)
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.small)
            .background(
                Capsule()
                    .stroke(theme.colors.accent, lineWidth: 1)
            )
            .foregroundColor(theme.colors.accent)
        }
    }
    
    // MARK: - Content Section
    
    private func contentSection(movieDetails: MovieDetails) -> some View {
        VStack(spacing: theme.spacing.large) {
            // Tab selector
            tabSelector
            
            // Tab content
            tabContent(movieDetails: movieDetails)
                .padding(.horizontal, theme.spacing.medium)
        }
        .background(theme.colors.background)
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.medium) {
                ForEach(MovieDetailsSection.allCases, id: \.self) { tab in
                    Button(action: { viewModel.selectTab(tab) }) {
                        VStack(spacing: theme.spacing.xSmall) {
                            HStack(spacing: theme.spacing.xSmall) {
                                Image(systemName: tab.icon)
                                    .font(.caption)
                                
                                Text(tab.displayName)
                                    .font(theme.typography.body)
                            }
                            .foregroundColor(
                                viewModel.selectedTab == tab ?
                                theme.colors.accent :
                                    theme.colors.onSurface
                            )
                            
                            Rectangle()
                                .fill(theme.colors.accent)
                                .frame(height: 2)
                                .opacity(viewModel.selectedTab == tab ? 1 : 0)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, theme.spacing.medium)
        }
        .padding(.vertical, theme.spacing.small)
    }
    
    private func tabContent(movieDetails: MovieDetails) -> some View {
        Group {
            switch viewModel.selectedTab {
            case .overview:
                overviewTab(movieDetails: movieDetails)
            case .cast:
                castTab
            case .reviews:
                reviewsTab
            case .similar:
                similarTab
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTab)
    }
    
    // MARK: - Tab Content Views
    
    private func overviewTab(movieDetails: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.large) {
            // Overview text
            if !movieDetails.overview.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.small) {
                    Text("Overview")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.onBackground)
                    
                    Text(movieDetails.overview)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.onSurface)
                        .lineLimit(viewModel.showFullOverview ? nil : 3)
                    
                    if movieDetails.overview.count > 200 {
                        Button(action: viewModel.toggleFullOverview) {
                            Text(viewModel.showFullOverview ? "Show Less" : "Show More")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                }
            }
            
            // Movie details grid
            movieDetailsGrid(movieDetails)
            
            // Production info
            if !movieDetails.productionCompanies.isEmpty {
                productionSection(movieDetails)
            }
        }
    }
    
    private var castTab: some View {
        comingSoonView(
            title: "Cast & Crew",
            subtitle: "View the amazing cast and crew behind this movie",
            icon: "person.3.fill"
        )
    }
    
    private var reviewsTab: some View {
        comingSoonView(
            title: "Reviews",
            subtitle: "Read what critics and audiences are saying",
            icon: "text.bubble.fill"
        )
    }
    
    private var similarTab: some View {
        comingSoonView(
            title: "Similar Movies",
            subtitle: "Discover movies you might also enjoy",
            icon: "film.fill"
        )
    }
    
    // MARK: - Helper Views
    
    private func movieDetailsGrid(_ movieDetails: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            Text("Details")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.onBackground)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: theme.spacing.medium) {
                
                if let budget = movieDetails.formattedBudget {
                    detailItem("Budget", budget)
                }
                
                if let revenue = movieDetails.formattedRevenue {
                    detailItem("Revenue", revenue)
                }
                
                detailItem("Language", movieDetails.originalLanguage.uppercased())
                detailItem("Rating", "\(movieDetails.formattedVoteAverage)/10")
                
                if let mediumReleaseDate = movieDetails.mediumReleaseDate {
                    detailItem("Release Date", mediumReleaseDate)
                }
                
                detailItem("Votes", "\(movieDetails.voteCount)")
            }
        }
    }
    
    private func detailItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.onSurface)
            
            Text(value)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.onBackground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.small)
        .background(
            RoundedRectangle(cornerRadius: theme.layout.cornerRadius)
                .fill(theme.colors.surface)
        )
    }
    
    private func productionSection(_ movieDetails: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text("Production")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.onBackground)
            
            ForEach(movieDetails.productionCompanies.prefix(3), id: \.id) { company in
                Text(company.name)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.onSurface)
            }
        }
    }
    
    
    
    // MARK: - Coming Soon View
    
    private func comingSoonView(title: String, subtitle: String, icon: String) -> some View {
        VStack(spacing: theme.spacing.large) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(theme.colors.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(theme.colors.accent)
            }
            
            VStack(spacing: theme.spacing.small) {
                Text(title)
                    .font(theme.typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.onBackground)
                
                Text(subtitle)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Coming soon badge
            HStack(spacing: theme.spacing.small) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                
                Text("Coming Soon")
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.small)
            .background(
                Capsule()
                    .fill(theme.colors.accent.opacity(0.1))
            )
            .foregroundColor(theme.colors.accent)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(theme.spacing.large)
    }
}

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
            .foregroundColor(theme.colors.onAccent)
            .font(theme.typography.button)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(theme.animation.quick, value: configuration.isPressed)
    }
}

// MARK: - MovieSortOption Extension

extension MovieDetailsSection {
    var displayName: String {
        return rawValue
    }
}

// MARK: - Preview

#if DEBUG
struct MovieDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MovieDetailsViewModel(
            movieId: 550,
            repository: MovieDetailsRepository(
                remoteDataSource: MovieDetailsRemoteDataSource(networkManager: NetworkManager.shared),
                localDataSource: MovieDetailsLocalDataSource(swiftDataStack: try! .forTesting())
            ),
            sharingService: SharingService()
        )
        
        MovieDetailsView(viewModel: viewModel)
            .preferredColorScheme(.light)
        
        MovieDetailsView(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}
#endif
