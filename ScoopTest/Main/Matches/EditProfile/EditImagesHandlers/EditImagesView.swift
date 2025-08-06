//
//  ImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI

struct ImagesView: View {

    @State private var vm: EditImageViewModel
    private let columns = Array(repeating: GridItem(.fixed(105), spacing: 10), count: 3)
    private let userStore: CurrentUserStore
    
    
    init(dependencies: AppDependencies) {
        self.userStore = dependencies.userStore
        _vm = State(initialValue: EditImageViewModel(dep: dependencies))
    }
    
    var body: some View {
        CustomList {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(0..<6) {idx in
                    EditPhotoCell(picker: $vm.slots[idx].pickerItem, url: vm.slots[idx].url) {
                        vm.changeImage(at: idx)
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
