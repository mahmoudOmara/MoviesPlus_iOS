//
//  MovieDetailsResponseModel.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import MPCore

/// TMDB API response model for movie details
public struct MovieDetailsResponseModel: Codable {
    
    // MARK: - Core Properties
    
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let voteAverage: Double
    public let voteCount: Int
    public let popularity: Double
    public let originalLanguage: String
    public let originalTitle: String
    public let adult: Bool
    public let video: Bool
    
    // MARK: - Detailed Properties
    
    public let budget: Int
    public let revenue: Int
    public let runtime: Int?
    public let status: String
    public let tagline: String?
    public let homepage: String?
    public let imdbId: String?
    
    // MARK: - Collections and Related Content
    
    public let genres: [GenreModel]
    public let productionCompanies: [ProductionCompanyResponseModel]
    public let productionCountries: [ProductionCountryResponseModel]
    public let spokenLanguages: [SpokenLanguageResponseModel]
    public let belongsToCollection: MovieCollectionResponseModel?
    
    // MARK: - Coding Keys
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case adult
        case video
        case budget
        case revenue
        case runtime
        case status
        case tagline
        case homepage
        case imdbId = "imdb_id"
        case genres
        case productionCompanies = "production_companies"
        case productionCountries = "production_countries"
        case spokenLanguages = "spoken_languages"
        case belongsToCollection = "belongs_to_collection"
    }
}
