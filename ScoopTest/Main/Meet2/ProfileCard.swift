//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.
//

import SwiftUI

struct ProfileCard : View {
    
    let profile: UserProfile
    let dep: AppDependencies
    
    @State private var image: UIImage?
    
    @Binding var selectedProfile: UserProfile?
    
    
    var firstURL: URL? {
        guard let s = profile.imagePathURL?.first else {return nil}
        return URL(string: s)
    }
    
    var body: some View {
        
        ZStack {
            if let image = image {
                firstImage(image: image)
                    .onTapGesture { withAnimation(.easeInOut) { selectedProfile = profile} }
            }
        }
        .task {
            guard let url = firstURL else {return}
            image = try? await dep.cacheManager.fetchImage(for: url)
        }
    }
    private func firstImage(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 320, height: 422)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
    }
}
