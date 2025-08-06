//
//  ProductionCompanyResponseModel.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation

/// TMDB API response model for production company
public struct ProductionCompanyResponseModel: Codable {
    public let id: Int
    public let name: String
    public let logoPath: String?
    public let originCountry: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case logoPath = "logo_path"
        case originCountry = "origin_country"
    }
}
