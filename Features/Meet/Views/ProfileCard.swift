//
//  ProfileCard.swift
//  Scoop
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    
    //Injected
    @Bindable var vm: MeetViewModel
    @Bindable var ui: MeetUIState

    let profile: PendingProfile
    let inviteMode: (UserProfile) -> ProfileMode

    @State var palette: OverlayPalette = .placeholder
    @State private var isProfilePresented = false
    
    var body: some View {
        AppImage(image: profile.image, type: .meet)
            .task(id: profile.image) {await fetchColour()}
            .zoomTransition(images: images()) {
                cardOverlay
            } content: {
                profileView(profile.profile)
                    .onAppear { isProfilePresented = true }
                    .onDisappear { isProfilePresented = false }
            }
            .overlay(alignment: .bottomTrailing) { inviteButton }
    }
}

extension ProfileCard {
    //All card chrome (blur + scrim + text) lives in the transition's overlay, so the flights fade it as one unit over the flying image
    private var cardOverlay: some View {
        blurAndColour
            .overlay(alignment: .bottomLeading) {
                overlayText
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
            }
    }

    //A pixel-aligned copy of the card image wearing the blur + scrim: glur needs image pixels beneath it, and the raw card base then matches the flying image exactly
    private var blurAndColour: some View {
        Color.clear
            .overlay {
                Image(uiImage: profile.image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .modifier(BlurAndColorBackground(color: palette.surface, opacity: palette.scrimOpacity))
    }

    
    private var overlayText: some View {
        let p = profile.profile
        return VStack(alignment: .leading, spacing: 6) {
            Text(profile.profile.name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)

            
            Text("\(p.year) · \(p.degree) · \(p.hometown)")
                 .font(.body(15, .medium))
                 .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private var inviteButton: some View {
        InviteButton {
            ui.showInvite = profile
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
}

//Functions
extension ProfileCard {
    private func profileView(_ profile: UserProfile) -> some View {
        ProfileContainer(
            vm: ProfileViewModel(profile: profile, imageLoader: vm.imageLoader, defaults: vm.defaults),
            profileImages: images(),
            mode: inviteMode(profile)
        )
    }
    
    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.profiles.first { $0.profile.id == profile.id }.map { [$0.image] } ?? []
    }
    
    private func fetchColour() async {
        palette = await PopupColorExtractor.shared
            .extractPalette(profile.image, id: profile.id, prominence: .subtle)
    }
    
    private func images() -> [UIImage] {
        vm.profileImages[profile.id] ?? seedImages(for: profile.profile)
    }
}

struct BlurAndColorBackground: ViewModifier {
    
    var color: Color = .black
    var opacity: Double = 0.45
    
    
    var mixedColor: Color {
        color.mix(with: .black, by: 0.35, in: .device)
    }
    
    
    /// Where the gradient stops ramping. Below this the scrim is flat, which is
    /// what lets `OverlayPalette` solve contrast against a single known color.
    /// Keep in sync with `extractPalette(textRegionHeight:)`.
//    private let flatFrom: Double = 0.82

    func body(content: Content) -> some View {
        content
            .glur(radius: 12, offset: 0.82, interpolation: 0.4, direction: .down, noise: 0)
            .overlay { blackGradient }
            .clipShape(.rect(cornerRadius: CornerRadius.image))
    }
    
    private var blackGradient: some View {
        LinearGradient(
            stops: [
                .init(color: mixedColor.opacity(0),    location: 0.65),
                .init(color: mixedColor.opacity(0.3),  location: 0.8),
                .init(color: mixedColor.opacity(0.55), location: 0.85),
                .init(color: mixedColor.opacity(0.65), location: 1)
            ],
            startPoint: .top, endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}




/*
 
 let quickInviteHidden: Bool
 let onQuickInvite: (UIImage) -> Void

 
 .sendInviteSource(id: profile.profile.id) //Reports this card's frame as the quick-invite flight source

 
 //The zoom hides only the image view — the caption/button chrome drawn over
 //it must hide too, or it floats over the flight and the empty slot.
 private var zoomFlying: Bool { ImageZoom.isFlying(profile.profile.id) }

 
 private var infoSection: some View {
     VStack(alignment: .leading, spacing: Spacing.xs) {
         let p = profile.profile
         Text(p.name)
             .font(.title(26))
             .getRect($nameFrame, coordSpace: cardSpace)
             .foregroundStyle(Color.white)

         Text("\(p.year) · \(p.degree) · \(p.hometown)")
             .font(.body(16, .regular))
             .foregroundStyle(Color.white.opacity(0.9))
             .getRect($detailsFrame, coordSpace: cardSpace)
     }
 }
 
 private var backgroundBlur: some View {
     BackgroundBlur(image: profile.image, frames: [nameFrame, detailsFrame])
         .opacity(quickInviteHidden || zoomFlying ? 0 : 1)
         .animation(.easeOut(duration: 0.12), value: quickInviteHidden)
         .animation(zoomFlying ? nil : .quick, value: zoomFlying) //Hide instantly; the light blur band reads as a white flash if it fades
 }

 
 //Local view state
 @State private var nameFrame: CGRect = .zero
 @State private var detailsFrame: CGRect = .zero
 private let cardSpace = "ProfileCard"
 .coordinateSpace(name: cardSpace)
 //            .profileShrinkPress {onTap(profile.image)}

 .overlay(alignment: .bottomLeading) {cardOverlay}

 */
