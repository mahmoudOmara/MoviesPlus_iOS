//
//  MovieCollectionResponseModel.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation

/// TMDB API response model for movie collection
public struct MovieCollectionResponseModel: Codable {
    public let id: Int
    public let name: String
    public let posterPath: String?
    public let backdropPath: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}
