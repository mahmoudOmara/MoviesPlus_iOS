//
//  ImageLoaderView.swift
//  MPCore
//
//  Created by mac on 04/08/2025.
//

import SwiftUI
import SDWebImageSwiftUI

public struct ImageLoaderView: View {
    let imageURLString: String
    let contentMode: ContentMode

    public init(imageURLString: String, contentMode: ContentMode = .fit) {
        self.imageURLString = imageURLString
        self.contentMode = contentMode
    }

    public var body: some View {
        Rectangle()
            .opacity(0.001)
            .overlay {
                WebImage(url: URL(string: imageURLString))
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .allowsHitTesting(false)
            }
            .clipped()
    }
}

#Preview {
    ImageLoaderView(
        imageURLString: Constants.Development.randomImage,
        contentMode: .fill
    )
        .frame(width: 100, height: 200)
}
