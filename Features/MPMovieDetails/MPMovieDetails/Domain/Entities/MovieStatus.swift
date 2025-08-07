//
//  MovieStatus.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation

/// Movie release status
public enum MovieStatus: String, CaseIterable {
    case rumored = "Rumored"
    case planned = "Planned"
    case inProduction = "In Production"
    case postProduction = "Post Production"
    case released = "Released"
    case canceled = "Canceled"
    
    public var displayName: String {
        return rawValue
    }
}
