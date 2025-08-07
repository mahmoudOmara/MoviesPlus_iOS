//
//  LocalProductionCompanyModel.swift
//  MPMovieDetails
//
//  Created by mac on 06/08/2025.
//

import Foundation
import SwiftData

@Model
public class LocalProductionCompanyModel {
    public var id: Int
    public var name: String
    public var logoPath: String?
    
    // MARK: - Metadata

    /// When the movie was first cached
    public var createdAt: Date
    
    /// When the cached movie were last updated
    public var updatededAt: Date
    
    // MARK: - Initialization
    
    public init(id: Int, name: String, logoPath: String?) {
        self.id = id
        self.name = name
        self.logoPath = logoPath
        self.createdAt = Date()
        self.updatededAt = Date()
    }
}
