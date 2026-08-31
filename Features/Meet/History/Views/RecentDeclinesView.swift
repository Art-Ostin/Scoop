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
            .zoomTransition(images: heroImages, windDismiss: true) {
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

#if DEBUG

struct WindDismissHarness: View {

    private let photos = [Self.photo(.systemIndigo), Self.photo(.systemTeal)]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)

    var body: some View {
        ZoomNavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Declined Profiles")
                    .font(.title(32, .bold))
                    .padding(.top, 36)

                LazyVGrid(columns: columns, spacing: 20) {
                    card
                    Color.clear.aspectRatio(1 / 1.2, contentMode: .fit)
                    Color.clear.aspectRatio(1 / 1.2, contentMode: .fit)
                    lowCard //Second row, right — the low-slot carry regime under test
                }
            }
            .padding(.horizontal, Spacing.gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.canvasSunken.ignoresSafeArea())
            .overlay { harnessDismissLayer }
        }
        .environment(ZoomPresentationHost?.none)
        .ignoresSafeArea()
    }

    //Mirrors HistoryContainer.dismissButtonLayer — the motion probe for the canvas-restore
    //snap: the padding cancels the library's presentation overgrowth in the same layout pass.
    private var harnessDismissLayer: some View {
        GeometryReader { proxy in
            ScoopButton(style: .clearGlass, shape: Circle(), size: .xLarge, press: .grow) {
                //Harness motion probe only — the real button dismisses the cover
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.black)
                    .font(.icon(18, .heavy))
            }
            .padding(.bottom, Spacing.xxl
                + max(0, proxy.size.height + proxy.safeAreaInsets.top
                    + proxy.safeAreaInsets.bottom - UIScreen.main.bounds.height)) //Geometry: the library's canvas overgrowth, read from inside the safe-area frame
            .padding(.horizontal, Spacing.margin)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    private var card: some View {
        Color.clear
            .aspectRatio(1 / 1.2, contentMode: .fit)
            .overlay {
                Image(uiImage: photos[0])
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .zoomTransition(images: photos, windDismiss: true) {
                detail
            }
    }

    private var lowCard: some View {
        Color.clear
            .aspectRatio(1 / 1.2, contentMode: .fit)
            .overlay {
                Image(uiImage: photos[1])
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
            .zoomTransition(images: [photos[1], photos[0]], windDismiss: true) {
                detail
            }
    }

    //The library hosts this in its own vertical scroll — no ScrollView here
    private var detail: some View {
        VStack(spacing: Spacing.lg) {
            ImageCarousel()
            ForEach(0..<8, id: \.self) { _ in
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.fillGray)
                    .frame(height: 88)
                    .padding(.horizontal, Spacing.gutter)
            }
        }
        .padding(.bottom, Spacing.clearance)
    }

    private static func photo(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 600, height: 750)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.white.withAlphaComponent(0.35).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 150, y: 120, width: 300, height: 300))
            UIColor.black.withAlphaComponent(0.6).setFill()
            ctx.fill(CGRect(x: 0, y: 620, width: 600, height: 130))
        }
    }
}
#endif

//The layers appearing above the profileCard
extension HistoryCard {
    private var chrome: some View {
        ZStack {
            blurBand
            blurBackground.scrimGradient
        }
        .clipShape(.rect(cornerRadius: ZoomStyle.cornerRadius))
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(profile.name)
                    .font(.title(20, .bold))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }
        .overlay(alignment: .topTrailing) {
            expiryLabel
        }
    }

    @ViewBuilder
    private var expiryLabel: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            if let left = decline.timeLeft(asOf: context.date) {
                ZStack {
                    expiryPill(left)
                        .id(left)
                        .transition(.blurReplace)
                }
                .animation(.transition, value: left)

            }
        }
    }

    //One styling path, so the placeholder above stays an honest preview of the real label
    private func expiryPill(_ text: String) -> some View {
        Text(text)
            .font(.body(10, .medium))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 4) //Geometry: optical inset — the stroke hugs the glyphs
            .padding(.vertical, 2)
            .stroke(12, lineWidth: 0.5, color: Color.white)
            .padding(8)
            .padding(.horizontal, 2)
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
