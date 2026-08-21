//
//  HistoryCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 21/08/2026.
//

import Foundation
import SwiftUI

struct HistoryCard: View {

    //Injected
    let decline: DeclinedProfile
    let vm: HistoryViewModel

    //Local view state
    @State private var palette: OverlayPalette = .placeholder

    private var image: UIImage { decline.profile.image }
    private var profile: UserProfile { decline.profile.profile }

    private var heroImages: [UIImage] { vm.profileImages[profile.id] ?? [image] }

    var body: some View {
        Color.clear
            .aspectRatio(1 / 1.2, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .task(id: image) {
                palette = await PopupColorExtractor.shared.extractPalette(image, id: decline.id)
            }
            .task { await vm.loadProfileImages(profile) }
            .zoomTransition(images: heroImages) {
                chrome
            } content: {
                ProfileContainer(vm: profileVM,
                                 profileImages: heroImages, //Seeds the VM: the detail skips its own round-trip
                                 mode: .viewProfile)
            }
            .animation(.transition, value: palette) //Covers a genuine cache miss: extraction lands a frame late
    }
}

extension HistoryCard {

    private var profileVM: ProfileViewModel {
        let model = ProfileViewModel(profile: profile,
                                     imageLoader: vm.imageLoader,
                                     defaults: vm.defaults)
        model.viewProfileType = .view
        return model
    }
}

//The chrome's layers
extension HistoryCard {

    private var blurBackground: BlurAndGradientBackground {
        BlurAndGradientBackground(
            textRegion: BlurAndGradientBackground.profileRegion,
            blurRadius: 5, //Geometry: half ProfileCard's 10 — the grid cell is under half the card's width
            colour: palette.surface,
            scrimOpacity: palette.scrimOpacity
        )
    }

    private var chrome: some View {
        ZStack {
            blurBand
            blurBackground.scrimGradient //Unmasked: the veil starts ABOVE the blur ramp (0.72 vs 0.77),
                                         //so masking it to the ramp would square off its soft top edge
        }
        .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
        .overlay(alignment: .bottomLeading) {
            Text(profile.name)
                .font(.title(20, .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.sm)
        }
    }

    private var blurBand: some View {
        let spec = blurBackground
        return Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .glur(radius: spec.blurRadius, offset: spec.blurStart,
                  interpolation: spec.blurRamp, direction: .down, noise: 0)
            .mask {
                //Feather INSIDE the ramp, so every pixel the mask reveals already carries blur
                LinearGradient(stops: [
                    .init(color: .clear, location: spec.blurStart),
                    .init(color: .black, location: spec.blurStart + 0.08),
                    .init(color: .black, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            }
    }
}
