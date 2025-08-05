//
//  TMDBAPI.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//

import Foundation
import Moya

/// TMDB API service definition using Moya
public enum TMDBAPI {
    case genres
    case popularMovies(page: Int)
    case movieDetails(id: Int)
}

// MARK: - TargetType Conformance

extension TMDBAPI: TargetType {
    
    public var baseURL: URL {
        guard let url = URL(string: Constants.TMDB.baseURL) else {
            fatalError("Invalid base URL: \(Constants.TMDB.baseURL)")
        }
        return url
    }
    
    public var path: String {
        switch self {
        case .genres:
            return Constants.TMDB.Endpoints.genres
        case .popularMovies:
            return Constants.TMDB.Endpoints.trendingMovies
        case .movieDetails(let id):
            return "\(Constants.TMDB.Endpoints.movieDetails)/\(id)"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }
    
    public var task: Task {
        var parameters: [String: Any] = [
            Constants.TMDB.QueryParams.apiKey: Constants.TMDB.apiKey,
            Constants.TMDB.QueryParams.language: Constants.TMDB.Defaults.language
        ]
        
        switch self {
        case .popularMovies(let page):
            parameters[Constants.TMDB.QueryParams.page] = page
                                    
        case .movieDetails, .genres:
            break
        }
        
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    public var headers: [String: String]? {
        return [
            NetworkConstants.Headers.accept: NetworkConstants.ContentTypes.json,
        ]
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
}
