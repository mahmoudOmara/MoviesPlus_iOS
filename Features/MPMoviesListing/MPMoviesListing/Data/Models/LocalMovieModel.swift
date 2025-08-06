//
//  LocalMovieModel.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation
import SwiftData

/// SwiftData model representing a movie
@Model
public final class LocalMovieModel {
    
    
    // MARK: - Properties
    
    /// Unique identifier from TMDB
    @Attribute(.unique) public var id: Int
    
    /// Movie title
    public var title: String
    
    /// Movie overview/description
    public var overview: String
    
    /// Poster image path (relative to TMDB base URL)
    public var posterPath: String?

    /// Release date
    public var releaseDate: Date?
    
    /// Vote average rating (0.0 - 10.0)
    public var voteAverage: Double

    /// Associated genre IDs
    public var genreIds: [Int]
    
    // MARK: - Metadata
    
    /// When the movie was first cached
    public var createdAt: Date
    
    /// When the cached movie were last updated
    public var updatededAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        releaseDate: Date?,
        voteAverage: Double,
        genreIds: [Int]
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.genreIds = genreIds
        self.createdAt = Date()
        self.updatededAt = Date()
    }
}
