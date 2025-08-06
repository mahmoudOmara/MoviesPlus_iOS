//
//  GenreFilter.swift
//  MPMoviesListing
//
//  Created by mac on 06/08/2025.
//

import Foundation

public struct GenreFilter: Equatable {
    
    /// Selected genre IDs
    public var selectedGenreIds: Set<Int>
    
    /// Whether the filter is active
    public var isActive: Bool {
        return !selectedGenreIds.isEmpty
    }

    public init(selectedGenreIds: Set<Int> = []) {
        self.selectedGenreIds = selectedGenreIds
    }
    
    /// Toggles a genre in the filter
    /// - Parameter genreId: Genre ID to toggle
    public mutating func toggle(genreId: Int) {
        if selectedGenreIds.contains(genreId) {
            selectedGenreIds.remove(genreId)
        } else {
            selectedGenreIds.insert(genreId)
        }
    }
    
    /// Clears all selected genres
    public mutating func clear() {
        selectedGenreIds.removeAll()
    }
}
