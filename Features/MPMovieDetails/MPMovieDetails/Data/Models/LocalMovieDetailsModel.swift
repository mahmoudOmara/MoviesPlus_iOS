//
//  LocalMovieDetailsModel.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//


import Foundation
import SwiftData
import MPCore

@Model
public class LocalMovieDetailsModel {
    public var id: Int
    public var title: String
    public var overview: String
    public var posterPath: String?
    public var backdropPath: String?
    public var releaseDate: Date?
    public var voteAverage: Double
    public var voteCount: Int
    public var originalLanguage: String
    public var budget: Int
    public var revenue: Int
    public var runtime: Int?
    public var status: String
    public var tagline: String?
    public var genres: [LocalGenreModel]
    public var productionCompanies: [LocalProductionCompanyModel]

    
    // MARK: - Metadata

    /// When the movie was first cached
    public var createdAt: Date
    
    /// When the cached movie were last updated
    public var updatededAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: Date?,
        voteAverage: Double,
        voteCount: Int,
        originalLanguage: String,
        budget: Int,
        revenue: Int,
        runtime: Int?,
        status: String,
        tagline: String?,
        genres: [LocalGenreModel],
        productionCompanies: [LocalProductionCompanyModel]
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.originalLanguage = originalLanguage
        self.budget = budget
        self.revenue = revenue
        self.runtime = runtime
        self.status = status
        self.tagline = tagline
        self.genres = genres
        self.productionCompanies = productionCompanies
        self.createdAt = Date()
        self.updatededAt = Date()
    }
}
