//
//  ThemeColors.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//


import SwiftUI

/// Theme color palette with support for light/dark modes
public struct ThemeColors {
    
    // MARK: - Common Colors

    /// Primary action color
    public var accent: Color {
        Color.accentColor
    }
    
    /// Border/outline color
    public var outline: Color {
        Color(UIColor.separator)
    }
    
    /// Primary background color
    public var background: Color {
        Color(UIColor.systemBackground)
    }
    
    /// Secondary surface color (cards, etc.)
    public var surface: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    // MARK: - Text Colors

    /// Main text on background
    public var onBackground: Color {
        Color(UIColor.label)
    }

    /// Main text on surfaces
    public var onSurface: Color {
        Color(UIColor.secondaryLabel)
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
