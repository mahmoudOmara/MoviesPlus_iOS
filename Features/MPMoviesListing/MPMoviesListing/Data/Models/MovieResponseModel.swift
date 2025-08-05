//
//  MovieResponseModel.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation

// MARK: - Movie Response Models

/// Root response model for TMDB movie endpoints
public struct MovieResponseModel: Codable {
    
    /// Current page number
    public let page: Int
    
    /// Array of movie results
    public let results: [MovieModel]
    
    /// Total number of pages available
    public let totalPages: Int
    
    /// Total number of results across all pages
    public let totalResults: Int
    
    private enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

/// Individual movie model from TMDB API response
public struct MovieModel: Codable {
    
    /// Movie ID from TMDB
    public let id: Int
    
    /// Movie title
    public let title: String
    
    /// Movie overview/description
    public let overview: String
    
    /// Poster image path (relative to TMDB base URL)
    public let posterPath: String?
    
    /// Backdrop image path (relative to TMDB base URL)
    public let backdropPath: String?
    
    /// Release date string (YYYY-MM-DD format)
    public let releaseDate: String?
    
    /// Vote average rating (0.0 - 10.0)
    public let voteAverage: Double
    
    /// Number of votes
    public let voteCount: Int
    
    /// Popularity score
    public let popularity: Double
    
    /// Original language code
    public let originalLanguage: String
    
    /// Original title
    public let originalTitle: String
    
    /// Adult content flag
    public let adult: Bool
    
    /// Video flag
    public let video: Bool
    
    /// Associated genre IDs
    public let genreIds: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case adult
        case video
        case genreIds = "genre_ids"
    }
}
