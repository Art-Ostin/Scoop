//
//  CirclePhoto.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import SwiftUI

struct CirclePhoto: View {
    
    let url: URL
    
    var body: some View {
        CachedAsyncImage(url: url) { image in
            image.resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
        } placeholder: {
            ProgressView()
        }
    }
}


//#Preview {
//    CirclePhoto()
//}
