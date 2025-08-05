//
//  Constants.swift
//  MPCore
//
//  Created by mac on 04/08/2025.
//

import Foundation

public struct Constants {
    
    // MARK: - Development & Testing
    
    public struct Development {
        public static let randomImage = "https://picsum.photos/600/600"
        public static let isDebugMode: Bool = {
#if DEBUG
            return true
#else
            return false
#endif
        }()
        public static let enableLogging = isDebugMode
    }
    
    // MARK: - TMDB API Configuration
    
    public struct TMDB {
        public static let baseURL = "https://api.themoviedb.org/3"
        public static let imageBaseURL = "https://image.tmdb.org/t/p"
        
        // TMDB API Key - In a real app, this should be stored securely
        public static let apiKey = "4796003271ed53c39e0a9eea94fb558e"
        
        // API Endpoints
        public struct Endpoints {
            public static let genres = "/genre/movie/list"
            public static let trendingMovies = "/discover/movie"
            public static let movieDetails = "/movie"
        }
        
        // Query Parameters
        public struct QueryParams {
            public static let apiKey = "api_key"
            public static let language = "language"
            public static let page = "page"
        }
        
        // Default Values
        public struct Defaults {
            public static let language = "en-US"
        }
    }
}
