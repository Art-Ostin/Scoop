//
//  ProfileImages.swift
//  Scoop
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI

struct ProfileImages: View {

    //Injected
    @Bindable var vm: EditProfileViewModel
    @Binding var isEditingImage: Bool //Raised while a cell's editor owns the screen

    //Local view state
    private let columnCount = 3
    private let pressScale: CGFloat = 0.92 //A cell's press depth; a held photo lifts out of however far the press has got
    //The one corner a grid-edge photo presents to the card's own corner — the dial for how concentric the grid reads
    private let outerCorner: CGFloat = CornerRadius.lg

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount) //Geometry: photo-grid gutter, held clear for the .tile shadow
    }

    //The photos a drag may move, in screen order: every loaded photo, or none while the gallery isn't safely aligned
    private var movablePhotos: [Int] {
        vm.canReorderPhotos ? Array(vm.photoOrder.prefix(vm.images.count)) : []
    }

    var body: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 16) {
                //Keyed by photo, not slot: a drop moves the cells themselves, and each zoom source travels with its photo
                ForEach(Array(vm.photoOrder.enumerated()), id: \.element) { slot, photo in
                    photoCell(slot)
                        .reorderableCell(photo)
                }
            }
            //Hold a photo to lift it; the others make room, and the new order waits for Save
            .reorderableGrid(movablePhotos, pressScale: pressScale, pressResponse: ZoomStyle.pressDownResponse) { from, to in
                vm.movePhoto(from: from, to: to)
            } preview: { photo, slot in
                liftedPhoto(photo, slot: slot)
            }
            .padding(-6)
        } header: {
            Text("Images")
                .padding(.leading, -Spacing.sm) //Geometry: negates the header's row inset so it lines up with the large title
        }
        .headerProminence(.standard)
    }
}

extension ProfileImages {

    //Grid-edge photos round the corner they present to the card harder than their inward ones
    private func corners(for slot: Int) -> RectangleCornerRadii {
        let inner = CornerRadius.smallImage
        let firstColumn = slot % columnCount == 0
        let lastColumn = slot % columnCount == columnCount - 1
        let firstRow = slot < columnCount
        let lastRow = slot >= EditProfileViewModel.photoSlots - columnCount

        return RectangleCornerRadii(
            topLeading:     firstRow && firstColumn ? outerCorner : inner,
            bottomLeading:  lastRow  && firstColumn ? outerCorner : inner,
            bottomTrailing: lastRow  && lastColumn  ? outerCorner : inner,
            topTrailing:    firstRow && lastColumn  ? outerCorner : inner)
    }

    //The grid is always `EditProfileViewModel.photoSlots` slots, but `vm.images` carries only the photos that
    //resolved — ImageLoader compactMaps away every path that is missing or fails to fetch, so
    //an account with a gap in its gallery hands us a short array. Empty slots wear the
    //placeholder, exactly as they do before the load lands.
    private func image(at slot: Int) -> UIImage {
        vm.images.indices.contains(slot) ? vm.images[slot] : EditProfileViewModel.placeholder
    }

    private func photoCell(_ slot: Int) -> some View {
        let image = image(at: slot)
        return ReorderSlotReader(slot: slot) { shown in
            ProfilePhoto(image: image, corners: corners(for: shown)) //Mid-drag, the corners of the slot it has slid to
        }
        .zoomTransition(
            images: [image],
            showsCardShadow: false, //The grid's cells rest flat on the section surface
            cornerRadius: CornerRadius.smallImage,
            pressScale: pressScale,
            windDismiss: true, //The Declined Profiles' close: a flick rides past the cell and lands with a bounce
            squeezeLanding: true //Save and Cancel drop the photo into its cell: a squeeze below its size, then a spring back out
        ) {
            editBadge //Card chrome: the flight fades it out rather than flying it
        } content: {
            editor(index: slot, image: image)
        }
        .disabled(!vm.galleryIsCurrent) //Photos loaded before the last save landed: an edit would file under the wrong stored photo
    }

    //The photo in the hand: the cell's own face without its Button, cut for the slot it would land in
    private func liftedPhoto(_ photo: Int, slot: Int) -> some View {
        let image = vm.photoOrder.firstIndex(of: photo).map { image(at: $0) } ?? EditProfileViewModel.placeholder
        return ProfilePhoto(image: image, corners: corners(for: slot))
            .overlay { editBadge }
    }

    private var editBadge: some View {
        ImageEditButton()
            .padding(Spacing.xxs)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func editor(index: Int, image: UIImage) -> some View {
        ProfileImageEditor(importedImage: ImageSlot(index: index, image: image)) { updatedImage in
            Task { vm.changeImage(image: updatedImage) } //Next turn: the cell swap and the upload kick-off never hold the collapse's first frame
        }
        //The screen's own presence IS the flag — nothing else here knows the zoom is up. It drops
        //on teardown, i.e. AFTER the collapse lands, so the drag stays disowned for the whole flight.
        .onAppear { isEditingImage = true }
        .onDisappear { isEditingImage = false }
    }
}
