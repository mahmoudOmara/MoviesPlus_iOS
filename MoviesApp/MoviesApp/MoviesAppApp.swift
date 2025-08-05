//
//  MoviesAppApp.swift
//  MoviesApp
//
//  Created by mac on 04/08/2025.
//

import SwiftUI
import MPMoviesListing

@main
struct MoviesAppApp: App {
    let vm: MovieListViewModel = {
        let repo = MovieRepository()
        return MovieListViewModel(repository: repo)
    }()
    
    var body: some Scene {
        WindowGroup {
            MovieListView(viewModel: vm)
                .themedEnvironment()
        }
    }
}
