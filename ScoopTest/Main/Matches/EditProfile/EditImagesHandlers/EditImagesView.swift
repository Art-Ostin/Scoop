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
        _vm = State(initialValue: EditImageViewModel(dep: dep))
    }
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
           await vm.loadUpImages()
        }
        .padding(.horizontal, 32)
    }
}
