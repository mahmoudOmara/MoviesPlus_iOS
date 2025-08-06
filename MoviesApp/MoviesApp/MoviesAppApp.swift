//
//  MoviesAppApp.swift
//  MoviesApp
//
//  Created by mac on 04/08/2025.
//

import SwiftUI
import MPCore
import MPMoviesListing

@main
struct MoviesAppApp: App {
    let vm: MovieListViewModel
    
    init() {
        do {
            try SwiftDataStack.configureShared(with: [LocalMovieModel.self])
        } catch {
            fatalError("Failed to configure SwiftDataStack: \(error)")
        }
        
        let repo = MovieRepository()
        vm = MovieListViewModel(repository: repo)

    }
    
    var body: some Scene {
        WindowGroup {
            MovieListView(viewModel: vm)
                .themedEnvironment()
        }
    }
}
