//
//  ViewMode.swift
//  MPMoviesListing
//
//  Created by mac on 05/08/2025.
//

import Foundation

public enum ViewMode: String, CaseIterable {
    case grid = "grid"
    case list = "list"
    
    public var systemImage: String {
        switch self {
        case .grid:
            return "square.grid.2x2"
        case .list:
            return "list.bullet"
        }
    }
}
