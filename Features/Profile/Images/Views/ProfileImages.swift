//
//  ImageView.swift
//  Scoop
//
//  Created by Art Ostin on 23/07/2025.
// Allow Editing on their profile and the option to cancel it. To


import SwiftUI
import PhotosUI


struct ProfileImages: View {

    @Bindable var vm: EditProfileViewModel
    @Binding var selectedImage: ImageSlot?
    //Cells flex to the container so the grid's outer edges land on the row's edges;
    //the 22pt gap is what stays fixed, since a narrower gap re-pools the cell shadows
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 22), count: 3) //Geometry: photo-grid gutter, held clear for the .tile shadow

    var body: some View {
            LazyVGrid(columns: columns, spacing: Spacing.lg) {
                ForEach(0..<6) {index in
                    let image = vm.images[index]
                    ImageCell(image: image)
                        .shrinkPress {
                            selectedImage = ImageSlot(index: index, image: image)
                        }
                }
            }
            .frame(maxWidth: 464) //Geometry: 3 × 140 + 2 × 22 — caps photo growth in landscape
    }
}
