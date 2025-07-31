//
//  CachedAsyncImage.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/07/2025.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    @Environment(\.appDependencies) private var dependencies
    let url: URL
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .task{ await load() }
            }
        }
    }
    private func load() async {
        uiImage = try? await dependencies.imageCache.fetchImage(for: url)
    }
}

//#Preview {
//    CachedAsyncImage()
//}
