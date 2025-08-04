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
}
