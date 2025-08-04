//
//  Theme.swift
//  MPCore
//
//  Created by mac on 05/08/2025.
//


import SwiftUI

/// Main theme configuration for the MoviesPlus app
/// Provides centralized styling system
public final class Theme {
    
    // MARK: - Singleton
    
    fileprivate static let shared = Theme()
    
    private init() {}
    
    // MARK: - Animation
    
    public var animation: ThemeAnimation {
        return ThemeAnimation()
    }
    
    // MARK: - Color Palette
    
    public var colors: ThemeColors {
        return ThemeColors()
    }
    
    // MARK: - Layout
    
    public var layout: ThemeLayout {
        return ThemeLayout()
    }
    
    // MARK: - Spacing
    
    public var spacing: ThemeSpacing {
        return ThemeSpacing()
    }
    
    // MARK: - Typography
    
    public var typography: ThemeTypography {
        return ThemeTypography()
    }
}

// MARK: - Environment Extension

public extension EnvironmentValues {
    
    /// Custom environment key for theme access
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

/// Environment key for theme access
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.shared
}

// MARK: - View Extensions

public extension View {
    
    /// Applies theme environment to the view hierarchy
    /// - Parameter theme: The theme to apply
    /// - Returns: View with theme environment
    func themedEnvironment() -> some View {
        self.environment(\.theme, Theme.shared)
    }
}
