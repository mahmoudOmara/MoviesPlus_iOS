//
//  GenreResponseModel.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation
import MPCore

/// Root response model for TMDB genres endpoint
public struct GenreResponseModel: Codable {
    
    /// Array of genre results
    public let genres: [GenreModel]
}
