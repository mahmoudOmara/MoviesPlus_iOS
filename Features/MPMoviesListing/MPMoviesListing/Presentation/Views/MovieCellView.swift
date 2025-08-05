//
//  MovieCellView.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import SwiftUI
import MPCore

/// Individual movie cell component for both grid and list layouts
public struct MovieCellView: View {
    
    // MARK: - Properties
    
    let movie: Movie
    let genres: [Genre]
    let viewMode: ViewMode
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    // MARK: - Initialization
    
    public init(
        movie: Movie,
        genres: [Genre],
        viewMode: ViewMode,
        onTap: @escaping () -> Void
    ) {
        self.movie = movie
        self.genres = genres
        self.viewMode = viewMode
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: onTap) {
            if viewMode == .grid {
                gridLayout
            } else {
                listLayout
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: theme.layout.cornerRadius)
                .fill(theme.colors.surface)
                .shadow(
                    color: theme.layout.shadowColor,
                    radius: theme.layout.shadowRadius,
                    x: theme.layout.shadowOffset.width,
                    y: theme.layout.shadowOffset.height
                )
        )
    }
    
    // MARK: - Grid Layout
    
    private var gridLayout: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            posterImage
                .aspectRatio(2/3, contentMode: .fit)
                .clipped()
            
            
            VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
                Text(movie.title)
                    .font(theme.typography.title)
                    .foregroundColor(theme.colors.onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let releaseYear = movie.releaseYear {
                    Text(releaseYear)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.onSurface)
                }
                
                ratingView
            }
            .padding(.horizontal, theme.spacing.small)
            .padding(.bottom, theme.spacing.small)
        }
        .background(theme.colors.surface)
        .cornerRadius(theme.layout.cornerRadius)
    }
    
    // MARK: - List Layout
    
    private var listLayout: some View {
        HStack(spacing: theme.spacing.medium) {
            posterImage
                .frame(width: 80, height: 120)
                .clipped()
            
            VStack(alignment: .leading, spacing: theme.spacing.small) {
                VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
                    Text(movie.title)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.onSurface)
                        .lineLimit(2)
                    
                    if let releaseYear = movie.releaseYear {
                        Text(releaseYear)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.onSurface)
                    }
                }
                
                overviewText
                
                Spacer()
                
                HStack {
                    ratingView
                    
                    Spacer()
                    
                    genreChips
                }
            }
        }
        .padding(theme.spacing.medium)
        .background(theme.colors.surface)
        .cornerRadius(theme.layout.cornerRadius)
    }
    
    // MARK: - Shared Components
    
    @ViewBuilder
    private var posterImage: some View {
        if let posterURL = movie.posterURL {
            ImageLoaderView(imageURLString: posterURL, contentMode: .fill)
                .cornerRadius(theme.layout.cornerRadius)
        } else {
            ZStack {
                Rectangle()
                    .fill(theme.colors.surface)
                
                VStack(spacing: theme.spacing.small) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(theme.colors.onSurface)
                    
                    Text("No Image")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.onSurface)
                }
            }
            .cornerRadius(theme.layout.cornerRadius)
        }
    }
    
    private var ratingView: some View {
        HStack(spacing: theme.spacing.xSmall) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(theme.colors.warning)
            
            Text(movie.formattedVoteAverage)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.onSurface)
        }
    }
    
    private var overviewText: some View {
        ZStack {
            if viewMode == .list {
                Text(movie.overview)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.onSurface)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var genreChips: some View {
        HStack(spacing: theme.spacing.xSmall) {
            ForEach(genres.prefix(2)) { genre in
                Text(genre.name)
                    .font(theme.typography.caption)
                    .padding(.horizontal, theme.spacing.small)
                    .padding(.vertical, theme.spacing.xSmall)
                    .background(
                        Capsule()
                            .fill(theme.colors.accent.opacity(0.1))
                    )
                    .foregroundColor(theme.colors.accent)
            }
            
            if genres.count > 2 {
                Text("+\(genres.count - 2)")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.onSurface)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
fileprivate struct MovieCellPreviewWrapper: View {
    @Environment(\.theme) private var theme
    
    private let sampleMovie = Movie.sample
    private let sampleGenre = Genre.sample

    var body: some View {
        VStack(spacing: 20) {
            MovieCellView(
                movie: sampleMovie,
                genres: [sampleGenre],
                viewMode: .grid,
                onTap: {},
            )
            .frame(width: 160)
            
            MovieCellView(
                movie: sampleMovie, genres: [sampleGenre],
                viewMode: .list,
                onTap: {},
            )
            .frame(height: 150)
        }
        .padding()
        .background(theme.colors.background)
    }
}

struct MovieCellView_Previews: PreviewProvider {
    static var previews: some View {
        MovieCellPreviewWrapper()
            .preferredColorScheme(.light)
        MovieCellPreviewWrapper()
            .preferredColorScheme(.dark)
    }
}
#endif
