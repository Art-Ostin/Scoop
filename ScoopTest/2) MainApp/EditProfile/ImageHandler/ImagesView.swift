//
//  ImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI

struct ImagesView: View {
    
    let columns = Array(repeating: GridItem(.fixed(105), spacing: 10), count: 3)
    
    @State var vm = ImageViewModel()
    
    var body: some View {
       
        CustomList {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(0..<6) {idx in
                    PhotoCell2(picker: $vm.pickerItems[idx], urlString: vm.imageURLs[idx], image: vm.selectedImages[idx]) {
                        vm.loadImage(at: idx)
                    }
                }
            }
            .padding(.horizontal)
        }
        .task {
          try? await CurrentUserStore.shared.loadUser()
          vm.seedFromCurrentUser()
        }
        .padding(.horizontal, 32)
    }
}


#Preview {
    ImagesView()
}

/*
 VStack {
     if let urls = CurrentUserStore.shared.user?.imagePathURL {
         ForEach(urls, id: \.self) {url in
             if let url = URL(string: url) {
                 AsyncImage(url: url) { Image in
                     Image
                         .resizable()
                         .scaledToFill()
                         .frame(width: 150, height: 150)
                 } placeholder: {
                     ProgressView()
                 }
             }
         }
     }
 }
 */

