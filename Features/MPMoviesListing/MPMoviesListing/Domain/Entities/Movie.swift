//
//  Movie.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation
import MPCore

/// Domain entity representing a movie in the MovieList feature
/// This is independent of persistence and API models
public struct Movie: Identifiable, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier from TMDB
    public let id: Int
    
    /// Movie title
    public let title: String
    
    /// Movie overview/description
    public let overview: String
    
    /// Poster image path (relative to TMDB base URL)
    public let posterPath: String?
    
    /// Release date
    public let releaseDate: Date?
    
    /// Vote average rating (0.0 - 10.0)
    public let voteAverage: Double
    
    /// Associated genre IDs
    public let genreIds: [Int]
    
    // MARK: - Initialization
    
    public init(
        id: Int,
        title: String,
        overview: String = "",
        posterPath: String? = nil,
        releaseDate: Date? = nil,
        voteAverage: Double = 0.0,
        genreIds: [Int] = []
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.genreIds = genreIds
    }
}

// MARK: - Computed Properties

public extension Movie {
    
    /// Full poster URL using TMDB base URL
    var posterURL: String? {
        guard let posterPath = posterPath else { return nil }
        return "\(Constants.TMDB.imageBaseURL)/\(Constants.TMDB.ImageSizes.poster)\(posterPath)"
    }
    
    /// Formatted release year
    var releaseYear: String? {
        return releaseDate?.yearString
    }
    
    var formattedVoteAverage: String {
        return String(format: "%.1f", voteAverage)
    }
}

// MARK: - Sample Data

public extension Movie {
    
    /// Sample movie for previews and testing
    static let sample = Movie(
        id: 123456,
        title: "Sample Movie",
        overview: "This is a sample movie overview for testing and preview purposes. It contains enough text to demonstrate truncation functionality.",
        posterPath: "/sample_poster.jpg",
        releaseDate: Date(),
        voteAverage: 8.5,
        genreIds: [28, 12, 16]
    )
}
