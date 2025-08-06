//
//  MovieResponseModel.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation

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
