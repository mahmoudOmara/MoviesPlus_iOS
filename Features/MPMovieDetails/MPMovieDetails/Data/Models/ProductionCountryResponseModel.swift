//
//  ProductionCountryResponseModel.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation

/// TMDB API response model for production country
public struct ProductionCountryResponseModel: Codable {
    public let iso31661: String
    public let name: String
    
    private enum CodingKeys: String, CodingKey {
        case iso31661 = "iso_3166_1"
        case name
    }
}
