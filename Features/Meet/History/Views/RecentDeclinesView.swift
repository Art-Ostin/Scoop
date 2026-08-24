//
//  RecentDeclinesView.swift
//  Scoop
//
//  Created by Art Ostin on 22/08/2026.
//

import SwiftUI

struct RecentDeclines: View {
    
    //Injected
    let declines: [DeclinedProfile]
    let profileImages: [String: [UIImage]]
    let imageLoader: ImageLoading
    let defaults: DefaultsManaging
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    
    var body: some View {
        if declines.isEmpty {
            pastDeclinePlaceholder
        } else {
            pastDeclineCards
        }
    }
}

extension RecentDeclines {
    private var pastDeclinePlaceholder: some View {
        Text("No Profiles")
    }
    
    private var pastDeclineCards: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(declines) { decline in
                HistoryCard(decline: decline,
                            heroImages: heroImages(for: decline),
                            imageLoader: imageLoader,
                            defaults: defaults)
            }
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.bottom, Spacing.clearance)
    }
    
    //The card's own image stands in until the profile's full set has loaded
    private func heroImages(for decline: DeclinedProfile) -> [UIImage] {
        profileImages[decline.id] ?? [decline.profile.image]
    }
}


//MARK: The individual Profile Card
struct HistoryCard: View {
    //Injected
    let decline: DeclinedProfile
    let heroImages: [UIImage]
    let imageLoader: ImageLoading
    let defaults: DefaultsManaging

    //Local view state
    @State private var palette: OverlayPalette = .placeholder

    private var image: UIImage { decline.profile.image }
    private var profile: UserProfile { decline.profile.profile }

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
            .zoomTransition(images: heroImages) {
                chrome
            } content: {
                profileView
            }
            .animation(.transition, value: palette) //Covers a genuine cache miss: extraction lands a frame late
    }
}

//The Profile View
extension HistoryCard {
    private var profileView: some View {
        ProfileContainer(vm: profileVM,
                         profileImages: heroImages, //Seeds the VM: the detail skips its own round-trip
                         mode: .viewProfile)
    }

    private var profileVM: ProfileViewModel {
        let model = ProfileViewModel(profile: profile,
                                     imageLoader: imageLoader,
                                     defaults: defaults)
        model.viewProfileType = .view
        return model
    }
}

//The layers appearing above the profileCard
extension HistoryCard {
    private var chrome: some View {
        ZStack {
            blurBand
            blurBackground.scrimGradient
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
    
    private var blurBackground: BlurAndGradientBackground {
        BlurAndGradientBackground(
            textRegion: BlurAndGradientBackground.profileRegion,
            blurRadius: 5, //Geometry: half ProfileCard's 10 — the grid cell is under half the card's width
            colour: palette.surface,
            scrimOpacity: palette.scrimOpacity
        )
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
