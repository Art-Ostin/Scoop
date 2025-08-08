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
    
    
    init(dep: AppDependencies) {
        _vm = State(initialValue: EditImageViewModel(profileManager: dep.profileManager, storageManager: dep.storageManager, user: dep.userManager))
    }
    
    var body: some View {
        CustomList {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(0..<6) {idx in
                    EditPhotoCell(picker: $vm.slots[idx].pickerItem, url: vm.slots[idx].url) {
                       try? await  vm.changeImage(at: idx)
                    }
                }
            }
            .padding(.horizontal)
        }
        .task {
            try? await vm.user.loadUser()
            vm.assignSlots()
        }
        .onChange(of: vm.user.user?.imagePathURL) {
            vm.assignSlots() // runs only when the profile data really changes
        }
        .padding(.horizontal, 32)
    }
}
