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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3) //Geometry: photo-grid gutter, held clear for the .tile shadow

    var body: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<6) {index in
                    photoCell(index)
                }
            }
            .padding(.horizontal, -6)
        } header: {
            Text("Images")
                .padding(.leading, -Spacing.sm) //Geometry: negates the header's row inset so it lines up with the large title
        }
        .headerProminence(.standard)
    }
}

extension ProfileImages {

    //The tapped photo morphs into its editor, the same flight a Meet card wears — one image,
    //cut to the cell's own radius, pressing deeper than a full-width card would.
    private func photoCell(_ index: Int) -> some View {
        let image = vm.images[index]
        return ProfilePhoto(image: image)
            .zoomTransition(
                images: [image],
                showsCardShadow: false, //The grid's cells rest flat on the section surface
                cornerRadius: CornerRadius.smallImage,
                pressScale: 0.92,
                continuousCollapse: true, //Shrinks and travels home as one motion; a dive past a grid cell reads as a detour
                dismissDurationScale: 1.5 //Folding a whole screen into a 110pt cell is a huge shrink over a short trip: the tuned clock reads fast on it
            ) {
                editBadge //Card chrome: the flight fades it out rather than flying it
            } content: {
                editor(index: index, image: image)
            }
    }

    private var editBadge: some View {
        ImageEditButton()
            .padding(Spacing.xxs)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func editor(index: Int, image: UIImage) -> some View {
        ProfileImageEditor(importedImage: ImageSlot(index: index, image: image)) { updatedImage in
            Task { try await vm.changeImage(image: updatedImage) }
        }
    }
}
