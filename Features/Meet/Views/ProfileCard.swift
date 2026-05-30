//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {

    let onTap: () -> Void
    let onQuickInvite: () -> Void
    let profile: PendingProfile
    let size: CGFloat
    let imageLoader: ImageLoading
    // While a morph is live for this profile, the morph surface *is* the button,
    // so the real one hides to avoid a duplicate during expand/collapse.
    var isMorphing: Bool = false

    private let cardCornerRadius: CGFloat = 22

    @State private var image: UIImage?
    @State private var detailsFrame: CGRect = .zero
    @State private var nameFrame: CGRect = .zero


    var body: some View {
        Image(uiImage: displayImage)
            .resizable()
            .defaultImage(size, cardCornerRadius)
            .overlay { backgroundBlur }
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(Color.appCanvas)
            )
            .customSubtleShadow(strength: 4) //Keep Shadow here. Works Nicely
            .overlay(alignment: .bottomLeading) { cardOverlay }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .coordinateSpace(name: ProfileCard.cardSpace)
            .onPreferenceChange(TextFrameKey.self) { detailsFrame = $0 }
            .onPreferenceChange(NameFrameKey.self) { nameFrame = $0 }
            .task(id: profile.id) {
                image = try? await imageLoader.fetchFirstImage(profile: profile.profile)
            }
    }

    private var displayImage: UIImage {
        image ?? profile.image
    }
}

extension ProfileCard {

    private var cardOverlay: some View {
        HStack(alignment: .bottom) {
            infoSection
            Spacer()
            inviteButton
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
    }

    private var inviteButton: some View {
        Button {
            onQuickInvite()
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
        }
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        .background(
            Circle()
                .fill(Color.accent)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
        )
        .opacity(isMorphing ? 0 : 1)
        .anchorPreference(key: InviteIconBoundsKey.self, value: .bounds) {
            [profile.profile.id: $0]
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let p = profile.profile
            Text(p.name)
                .font(.body(22, .bold))
                .measure(key: NameFrameKey.self) { $0.frame(in: .named(ProfileCard.cardSpace)) }

            Text("\(p.year) | \(p.degree) | \(p.hometown)")
                .font(.body(14, .medium))
                .measure(key: TextFrameKey.self) { $0.frame(in: .named(ProfileCard.cardSpace)) }
        }
        .foregroundStyle(Color.white)
        .font(.body(14, .medium))
    }
}

//AI Code
extension ProfileCard {
    
    fileprivate static let cardSpace = "ProfileCard.card"
    
    // Blurred copy of the image, masked to feathered rounded-rects that
    // track the text frames — gives a soft halo of blur only behind the text.
    private var backgroundBlur: some View {
        Image(uiImage: displayImage)
            .resizable()
            .scaledToFill()
            .frame(width: max(size, 0), height: max(size, 0))
            .blur(radius: 22)
            .mask {
                ZStack {
                    blurMask(for: nameFrame)
                    blurMask(for: detailsFrame)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .allowsHitTesting(false)
    }

    private func blurMask(for frame: CGRect) -> some View {
        let padX: CGFloat = 4
        let padY: CGFloat = 2
        let feather: CGFloat = 4
        let rect = frame.insetBy(dx: -padX, dy: -padY)
        return RoundedRectangle(cornerRadius: 12)
            .frame(width: max(rect.width, 0), height: max(rect.height, 0))
            .position(x: rect.midX, y: rect.midY)
            .blur(radius: feather)
            .opacity(frame == .zero ? 0 : 1)
    }
}

private struct TextFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct NameFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
