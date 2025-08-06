//
//  LocalGenreModel.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//


import Foundation
import SwiftData

/// SwiftData model representing a movie genre
@Model
public final class LocalGenreModel {
    
    // MARK: - Properties
    
    /// Unique identifier from TMDB
    @Attribute(.unique) public var id: Int
    
    /// Genre name
    public var name: String
        
    // MARK: - Metadata
    
    /// When the movie was first cached
    public var createdAt: Date
    
    /// When the cached movie were last updated
    public var updatededAt: Date
    
    // MARK: - Initialization
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.updatededAt = Date()

    }
}
