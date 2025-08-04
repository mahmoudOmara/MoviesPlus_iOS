//
//  NetworkConstants.swift
//  MPCore
//
//  Created by mac on 04/08/2025.
//

import Foundation

/// Network-related constants and configurations
struct NetworkConstants {
    
    // MARK: - Timeouts
    
    struct Timeouts {
        public static let request: TimeInterval = 30.0
        public static let resource: TimeInterval = 60.0
    }
    
    // MARK: - Headers
    
    struct Headers {
        public static let accept = "accept"
    }
    
    // MARK: - Content Types
    
    struct ContentTypes {
        public static let json = "application/json"
        public static let formURLEncoded = "application/x-www-form-urlencoded"
        public static let multipartFormData = "multipart/form-data"
    }
    
    // MARK: - HTTP Methods
    
    struct HTTPMethods {
        public static let get = "GET"
        public static let post = "POST"
        public static let put = "PUT"
        public static let delete = "DELETE"
        public static let patch = "PATCH"
    }
    
    
    // MARK: - Default Values
    
    struct Defaults {
        public static let maxRetryAttempts = 3
        public static let cacheSize = 50 * 1024 * 1024 // 50MB
    }
}
