//
//  SpokenLanguageResponseModel.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation

/// TMDB API response model for spoken language
public struct SpokenLanguageResponseModel: Codable {
    public let iso6391: String
    public let name: String
    public let englishName: String
    
    private enum CodingKeys: String, CodingKey {
        case iso6391 = "iso_639_1"
        case name
        case englishName = "english_name"
    }
}
