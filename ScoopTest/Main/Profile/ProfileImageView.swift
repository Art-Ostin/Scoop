//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct ProfileImageView: View {
    
    @Binding var vm: ProfileViewModel
    @Binding var isInviting: Bool
    
    let cache = NSCache<NSURL, UIImage>()
    
    var body: some View {
        
        let stringURLs = vm.p.imagePathURL
        
        GeometryReader { geo in
            TabView(selection: $vm.imageSelection) {
                if let urlString = stringURLs {
                    let size = geo.size.width - 24
                        ForEach (urlString.indices, id: \.self) {index in
                        let url = urlString[index]
                        if let url = URL(string: url) {
                            imageContainer(url: url, size: size, vm: $vm)
                                .tag(index)
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geo.size.width, height: 430)
        }
    }
}

struct imageContainer: View {

    let url: URL
    let size: CGFloat
    @Binding var vm: ProfileViewModel
    
    var body: some View {
        
        CachedAsyncImage(url: url) { Image in
            Image.resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()

        } placeholder: {
            ProgressView()
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
        .overlay(alignment: .bottomTrailing) {
            InviteButton(vm: vm)
                .padding(24)
        }
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
    }
    
}
