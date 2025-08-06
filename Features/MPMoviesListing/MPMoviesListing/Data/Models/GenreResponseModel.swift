//
//  GenreResponseModel.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation

// MARK: - Genre Response Models

/// Root response model for TMDB genres endpoint
public struct GenreResponseModel: Codable {
    
    /// Array of genre results
    public let genres: [GenreModel]
}

/// Individual genre model from TMDB API response
public struct GenreModel: Codable {
    
    /// Genre ID from TMDB
    public let id: Int
    
    /// Genre name
    public let name: String
}
