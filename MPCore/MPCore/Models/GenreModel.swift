//
//  GenreModel.swift
//  MPMoviesListing
//
//  Created by mac on 06/08/2025.
//

import Foundation

/// Individual genre model from TMDB API response
public struct GenreModel: Codable {
    
    /// Genre ID from TMDB
    public let id: Int
    
    /// Genre name
    public let name: String
}
