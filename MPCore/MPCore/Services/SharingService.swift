//
//  SharingService.swift
//  MPCore
//
//  Created by mac on 07/08/2025.
//

import SwiftUI
import Foundation

/// Protocol for sharing functionality
public protocol SharingServiceProtocol {
    /// Shares a movie with the given title and ID
    /// - Parameters:
    ///   - title: Movie title to share
    ///   - movieId: Movie ID for sharing
    ///   - sourceView: Source view for iPad popover presentation
    func shareMovie(title: String, movieId: Int, sourceView: UIView?)
}

/// Service for handling sharing functionality across the app
public final class SharingService: SharingServiceProtocol {
    
    public init() {}
    
    /// Shares a movie using UIActivityViewController
    /// - Parameters:
    ///   - title: Movie title to share
    ///   - movieId: Movie ID for sharing
    ///   - sourceView: Source view for iPad popover presentation
    public func shareMovie(title: String, movieId: Int, sourceView: UIView?) {
        let shareText = "Check out this movie: \(title)"
        let tmdbURL = "https://www.themoviedb.org/movie/\(movieId)"
        
        let activityItems: [Any] = [shareText, URL(string: tmdbURL) as Any]
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popoverController = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popoverController.sourceView = sourceView
                popoverController.sourceRect = sourceView.bounds
            } else {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    popoverController.sourceView = window.rootViewController?.view
                    popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
            }
        }
        
        // Present the activity controller
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                var presentingController = rootViewController
                while let presented = presentingController.presentedViewController {
                    presentingController = presented
                }
                
                presentingController.present(activityViewController, animated: true)
            }
        }
    }
}
