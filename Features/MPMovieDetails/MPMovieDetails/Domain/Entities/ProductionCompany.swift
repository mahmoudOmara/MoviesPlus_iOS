//
//  ProductionCompany.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import MPCore

/// Production company information
public struct ProductionCompany: Identifiable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let logoPath: String?
    
    public init(id: Int, name: String, logoPath: String? = nil) {
        self.id = id
        self.name = name
        self.logoPath = logoPath
    }
}

// MARK: - Computed Properties

extension ProductionCompany {
    
    /// Company logo URL
    public var logoURL: String? {
        guard let logoPath = logoPath else { return nil }
        return "\(Constants.TMDB.imageBaseURL)/\(Constants.TMDB.ImageSizes.profile)\(logoPath)"
    }
}
