//
//  Movie.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation

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
    
    /// Release date
    public let releaseDate: Date?
    
    /// Associated genre IDs
    public let genreIds: [Int]
    
    // MARK: - Initialization
    
    public init(
        id: Int,
        title: String,
        overview: String = "",
        releaseDate: Date? = nil,
        genreIds: [Int] = []
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.releaseDate = releaseDate
        self.genreIds = genreIds
    }
}
