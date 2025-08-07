//
//  MovieDetails.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import MPCore

/// Comprehensive movie details entity with all information needed for detailed view
public struct MovieDetails: Identifiable, Equatable, Hashable {
    
    // MARK: - Properties

    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: Date?
    public let voteAverage: Double
    public let voteCount: Int
    public let originalLanguage: String
    public let budget: Int
    public let revenue: Int
    public let runtime: Int?
    public let status: MovieStatus
    public let tagline: String?
    public let genres: [Genre]
    public let productionCompanies: [ProductionCompany]
        
    // MARK: - Initialization
    
    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        releaseDate: Date? = nil,
        voteAverage: Double,
        voteCount: Int,
        originalLanguage: String,
        budget: Int = 0,
        revenue: Int = 0,
        runtime: Int? = nil,
        status: MovieStatus = .released,
        tagline: String? = nil,
        genres: [Genre] = [],
        productionCompanies: [ProductionCompany] = [],
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.originalLanguage = originalLanguage
        self.budget = budget
        self.revenue = revenue
        self.runtime = runtime
        self.status = status
        self.tagline = tagline
        self.genres = genres
        self.productionCompanies = productionCompanies
    }
}

// MARK: - Computed Properties

public extension MovieDetails {

    /// Full poster URL for displaying movie poster
    var posterURL: String? {
        guard let posterPath = posterPath else { return nil }
        return "\(Constants.TMDB.imageBaseURL)/\(Constants.TMDB.ImageSizes.poster)\(posterPath)"
    }
    
    /// Full backdrop URL for hero image
    var backdropURL: String? {
        guard let backdropPath = backdropPath else { return nil }
        return "\(Constants.TMDB.imageBaseURL)/\(Constants.TMDB.ImageSizes.backdrop)\(backdropPath)"
    }
    
    /// Formatted vote average (e.g., "8.5")
    var formattedVoteAverage: String {
        return String(format: "%.1f", voteAverage)
    }
    
    /// Release year string
    var releaseYear: String? {
        return releaseDate?.yearString
    }
    
    var mediumReleaseDate: String? {
        return releaseDate?.mediumStrig
    }
    
    /// Formatted runtime (e.g., "2h 30m")
    var formattedRuntime: String? {
        guard let runtime = runtime, runtime > 0 else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Formatted budget (e.g., "$150M")
    var formattedBudget: String? {
        guard budget > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        
        if budget >= 1_000_000 {
            let millions = Double(budget) / 1_000_000
            return String(format: "$%.0fM", millions)
        } else if budget >= 1_000 {
            let thousands = Double(budget) / 1_000
            return String(format: "$%.0fK", thousands)
        } else {
            return formatter.string(from: NSNumber(value: budget))
        }
    }
    
    /// Formatted revenue (e.g., "$2.8B")
    var formattedRevenue: String? {
        guard revenue > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 1
        
        if revenue >= 1_000_000_000 {
            let billions = Double(revenue) / 1_000_000_000
            return String(format: "$%.1fB", billions)
        } else if revenue >= 1_000_000 {
            let millions = Double(revenue) / 1_000_000
            return String(format: "$%.0fM", millions)
        } else if revenue >= 1_000 {
            let thousands = Double(revenue) / 1_000
            return String(format: "$%.0fK", thousands)
        } else {
            return formatter.string(from: NSNumber(value: revenue))
        }
    }
    
    /// Genre names as comma-separated string
    var genreNames: String {
        return genres.map { $0.name }.joined(separator: ", ")
    }
}

// MARK: - Sample Data

public extension MovieDetails {
    /// Sample movie details for previews and testing
    static let sample = MovieDetails(
        id: 550,
        title: "Fight Club",
        overview: "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy. Their concept catches on, with underground \"fight clubs\" forming in every town, until an eccentric gets in the way and ignites an out-of-control spiral toward oblivion.",
        posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
        backdropPath: "/fCayJrkfRaCRCTh8GqN30f8oyQF.jpg",
        releaseDate: Calendar.current.date(from: DateComponents(year: 1999, month: 10, day: 15)),
        voteAverage: 8.4,
        voteCount: 26280,
        originalLanguage: "en",
        budget: 63000000,
        revenue: 100853753,
        runtime: 139,
        status: .released,
        tagline: "Mischief. Mayhem. Soap.",
        genres: [
            Genre(id: 18, name: "Drama"),
            Genre(id: 53, name: "Thriller"),
            Genre(id: 35, name: "Comedy")
        ],
        productionCompanies: [
            ProductionCompany(id: 508, name: "20th Century Fox", logoPath: "/7PzJdsLGlR7oW4J0J5Xcd0pHGRg.png"),
            ProductionCompany(id: 711, name: "Fox 2000 Pictures", logoPath: "/tEiIH5QesdheJmDAqQwvtN60727.png")
        ]
    )
}
