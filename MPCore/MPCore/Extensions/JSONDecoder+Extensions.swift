//
//  File.swift
//  MPCore
//
//  Created by mac on 04/08/2025.
//

import Foundation

extension JSONDecoder {
    
    /// Configured JSONDecoder for  API responses
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.apiDateFormatter)
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()
}
