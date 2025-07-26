//
//  ImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI

struct ImagesView: View {

    let columns = Array(repeating: GridItem(.fixed(105), spacing: 10), count: 3)
    
    @State var vm = ImageViewModel(storageManager: <#any StorageManaging#>, userStore: CurrentUserStore, profileManager: <#any ProfileManaging#>)
    
    
    let userStore: CurrentUserStore
    
    init(userStore: CurrentUserStore) {
        self.userStore = userStore
    }
    
    
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
          try? await userStore.loadUser()
          vm.seedFromCurrentUser()
        }
        .padding(.horizontal, 32)
    }
}

//
//#Preview {
//    ImagesView(userStore: CurrentUserStore())
//}
