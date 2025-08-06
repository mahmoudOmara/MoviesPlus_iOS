//
//  ThemeLayout.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//

import SwiftUI

/// Layout configuration for consistent component sizing and positioning
public struct ThemeLayout {
    public let cornerRadius: CGFloat = 12
    public let shadowColor = Color.black.opacity(0.1)
    public let shadowRadius: CGFloat = 4
    public let shadowOffset = CGSize(width: 0, height: 2)
}
