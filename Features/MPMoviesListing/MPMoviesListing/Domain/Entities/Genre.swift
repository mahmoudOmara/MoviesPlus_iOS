//
//  Genre.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation

/// Domain entity representing a movie genre
/// This is independent of persistence and API models
public struct Genre: Identifiable {
    
    // MARK: - Properties
    
    /// Unique identifier from TMDB
    public let id: Int
    
    /// Genre name
    public let name: String
    
    // MARK: - Initialization
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
