//
//  ImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
// Allow Editing on their profile and the option to cancel it. To


import SwiftUI

struct ImagesView: View {

    @Bindable var vm: EditProfileViewModel
    private let columns = Array(repeating: GridItem(.fixed(105), spacing: 10), count: 3)

    var body: some View {
        CustomList {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(0..<6) {idx in                    
                    EditPhotoCell(picker: $vm.slots[idx].pickerItem, image: vm.images[idx]) {
                        try await vm.changeImage(at: idx)
                    }
                }
            }
            .padding(.horizontal)
        }
        .task {
            if !vm.didAssignSlots {
                await vm.assignSlots()
            }
        }
        .padding(.horizontal, 32)
    }
}



