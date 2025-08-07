//
//  MovieDetailsSection.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

/// Available tabs in movie details view
public enum MovieDetailsSection: String, CaseIterable {
    case overview = "Overview"
    case cast = "Cast"
    case reviews = "Reviews"
    case similar = "Similar"
    
    public var icon: String {
        switch self {
        case .overview:
            return "info.circle"
        case .cast:
            return "person.3"
        case .reviews:
            return "text.bubble"
        case .similar:
            return "film"
        }
    }
}
