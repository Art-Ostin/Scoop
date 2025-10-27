//
//  ProfileImageTest2.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI

struct ProfileImageTest2: View {
    
    @State var vm: ProfileViewModel
    @State var images: [UIImage] = []
    @State var tabSelection: Int? = 0
    
    
    init(
        profile: ProfileModel,
        cacheManager: CacheManaging,
        images: [UIImage]? = [],
        tabSelection: Int? = nil
    ) {
        _vm = State(initialValue: ProfileViewModel(profileModel: profile, cacheManager: cacheManager))
        _images = State(initialValue: images ?? [])
        _tabSelection = State(initialValue: tabSelection)
    }
    
    
    var body: some View {
        ScrollView(.horizontal) {
          HStack(spacing: 0) {
            ForEach(images.indices, id: \.self) { i in
              ZStack {
                // This invisible view makes the container square based on the given width.
                Color.clear
                  .aspectRatio(1, contentMode: .fit)

                Image(uiImage: images[i])
                  .resizable()
                  .scaledToFit()
              }
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .clipped()
              .containerRelativeFrame(.horizontal) { length, _ in length - 16 } // width = page - padding
              .id(i)
            }
          }
          .scrollTargetLayout()
        }
        .scrollIndicators(.never)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $tabSelection, anchor: .center)
        .task {
           images = await vm.loadImages()
        }
    }
}

