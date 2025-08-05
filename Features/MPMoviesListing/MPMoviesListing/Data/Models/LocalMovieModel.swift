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
    
    /// Release date
    public var releaseDate: Date?
    
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
        overview: String = "",
        releaseDate: Date? = nil,
        genreIds: [Int]
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.releaseDate = releaseDate
        self.genreIds = genreIds
        self.createdAt = Date()
        self.updatededAt = Date()
    }
}
