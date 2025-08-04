//
//  ThemeColors.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//


import SwiftUI

/// Theme color palette with support for light/dark modes
public struct ThemeColors {
    
    // MARK: - Background / Surface

    /// Primary background color
    public var background: Color {
        Color(UIColor.systemBackground)
    }
    
    /// Secondary surface color (cards, etc.)
    public var surface: Color {
        Color(UIColor.secondarySystemBackground)
    }

    // MARK: - States

    /// Error color
    public var error: Color {
        Color.red
    }

    /// Warning color
    public var warning: Color {
        Color.orange
    }
}
