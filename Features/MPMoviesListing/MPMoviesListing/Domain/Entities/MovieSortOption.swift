//
//  MovieSortOption.swift
//  MPMoviesListing
//
//  Created by mac on 06/08/2025.
//

import Foundation

public enum MovieSortOption: String, CaseIterable {
    case popularity = "Popularity"
    case rating = "Rating"
    case releaseDate = "Release Date"
    case title = "Title"
    
    public var systemImage: String {
        switch self {
        case .popularity:
            return "flame"
        case .rating:
            return "star"
        case .releaseDate:
            return "calendar"
        case .title:
            return "textformat.abc"
        }
    }
}
