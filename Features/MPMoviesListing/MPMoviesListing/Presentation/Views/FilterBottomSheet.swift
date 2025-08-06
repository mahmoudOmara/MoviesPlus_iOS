//
//  FilterBottomSheet.swift
//  MovieList
//
//  Created by mac on 01/08/2025.
//

import SwiftUI
import MPCore

/// Bottom sheet for movie filtering and sorting options
public struct FilterBottomSheet: View {
    
    // MARK: - Properties
    
    let genres: [Genre]
    let currentFilter: GenreFilter
    let currentSortOption: MovieSortOption
    let onApply: (GenreFilter, MovieSortOption) -> Void
    
    @State private var selectedGenres: Set<Int>
    @State private var selectedSort: MovieSortOption
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    // MARK: - Initialization
    
    public init(
        genres: [Genre],
        currentFilter: GenreFilter,
        sortOption: MovieSortOption,
        onApply: @escaping (GenreFilter, MovieSortOption) -> Void
    ) {
        self.genres = genres
        self.currentFilter = currentFilter
        self.currentSortOption = sortOption
        self.onApply = onApply
        
        self._selectedGenres = State(initialValue: currentFilter.selectedGenreIds)
        self._selectedSort = State(initialValue: sortOption)
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    LazyVStack(spacing: theme.spacing.large) {
                        sortSection
                        genreSection
                    }
                    .padding(.horizontal, theme.spacing.medium)
                    .padding(.top, theme.spacing.medium)
                }
                
                bottomButtons
            }
            .background(theme.colors.background)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(theme.colors.accent)
                
                Spacer()
                
                Text("Filters & Sort")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.onBackground)
                
                Spacer()
                
                Button("Reset") {
                    selectedGenres.removeAll()
                    selectedSort = MoviesListingConstants.defaultMoviesSortOption
                }
                .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.medium)
            
            Divider()
                .background(theme.colors.outline)
        }
        .background(theme.colors.surface)
    }
    
    // MARK: - Sections
    
    private var sortSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            sectionHeader("Sort By")
            
            VStack(spacing: theme.spacing.small) {
                ForEach(MovieSortOption.allCases, id: \.self) { option in
                    sortOptionRow(option)
                }
            }
        }
    }
    
    private var genreSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            sectionHeader("Genres")
            
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 100), spacing: theme.spacing.medium)
                ],
                spacing: theme.spacing.medium
            ) {
                ForEach(genres, id: \.id) { genre in
                    genreChip(genre)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(theme.typography.title3)
            .foregroundColor(theme.colors.onBackground)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func sortOptionRow(_ option: MovieSortOption) -> some View {
        Button(action: { selectedSort = option }) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
                    Text(option.displayName)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.onBackground)
                    
                    Text(option.description)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.onSurface)
                }
                
                Spacer()
                
                if selectedSort == option {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.colors.accent)
                        .font(.title3)
                }
            }
            .padding(theme.spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: theme.layout.cornerRadius)
                    .fill(selectedSort == option ?
                          theme.colors.accent.opacity(0.1) :
                          theme.colors.surface)
                    .stroke(
                        selectedSort == option ?
                        theme.colors.accent :
                        theme.colors.outline.opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func genreChip(_ genre: Genre) -> some View {
        Button(action: {
            if selectedGenres.contains(genre.id) {
                selectedGenres.remove(genre.id)
            } else {
                selectedGenres.insert(genre.id)
            }
        }) {
            Text(genre.name)
                .font(theme.typography.caption)
                .padding(.horizontal, theme.spacing.medium)
                .padding(.vertical, theme.spacing.small)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(selectedGenres.contains(genre.id) ?
                              theme.colors.accent :
                              theme.colors.surface)
                        .stroke(
                            selectedGenres.contains(genre.id) ?
                            theme.colors.accent :
                            theme.colors.outline,
                            lineWidth: 1
                        )
                )
                .foregroundColor(
                    selectedGenres.contains(genre.id) ?
                    theme.colors.onAccent :
                    theme.colors.onSurface
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            Divider()
                .background(theme.colors.outline)
            
            HStack(spacing: theme.spacing.medium) {
                Button("Clear All") {
                    selectedGenres.removeAll()
                    selectedSort = MoviesListingConstants.defaultMoviesSortOption
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Apply Filters") {
                    let newFilter = GenreFilter(selectedGenreIds: selectedGenres)
                    onApply(newFilter, selectedSort)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.medium)
        }
        .background(theme.colors.surface)
    }
}

// MARK: - MovieSortOption Extension

public extension MovieSortOption {
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .popularity:
            return "Most popular movies first"
        case .rating:
            return "Highest rated movies first"
        case .releaseDate:
            return "Newest movies first"
        case .title:
            return "Alphabetical order"
        }
    }
}

// MARK: - Button Styles

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: theme.layout.cornerRadius)
                    .fill(theme.colors.accent)
            )
            .foregroundColor(theme.colors.onAccent)
            .font(theme.typography.button)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(theme.animation.quick, value: configuration.isPressed)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: theme.layout.cornerRadius)
                    .stroke(theme.colors.accent, lineWidth: 1)
            )
            .foregroundColor(theme.colors.accent)
            .font(theme.typography.button)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(theme.animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct FilterBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        FilterBottomSheet(
            genres: Array(repeating: Genre.sample, count: 5),
            currentFilter: GenreFilter(),
            sortOption: .popularity,
        ) { _, _ in }
        .preferredColorScheme(.light)
        
        FilterBottomSheet(
            genres: Array(repeating: Genre.sample, count: 5),
            currentFilter: GenreFilter(selectedGenreIds: [28, 12]),
            sortOption: .rating,
        ) { _, _ in }
        .preferredColorScheme(.dark)
    }
}
#endif
