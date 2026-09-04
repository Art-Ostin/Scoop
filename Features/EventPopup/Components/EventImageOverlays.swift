//
//  EventImageOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

let imageHorizontalPadding = Spacing.lg
let imageBottomPadding = Spacing.xs
let imageTopPadding = Spacing.xs

//Overlays
struct EventTitle: View {

    //Injected
    let title: String
    var textRect: Binding<CGRect> = .constant(.zero)
    var coordSpace: String? = nil

    ///The size this title lands at. A static because the event zoom's name morph lays its flying
    ///word out at the size it will land in — the two can never drift into a step at the hand-off.
    static func size(for title: String) -> CGFloat { title.starts(with: "Invite") ? 22 : 18 }

    var body: some View {
        Text(title)
            .font(.title(Self.size(for: title), .bold))
            .foregroundStyle(Color.white)
            .id(title)
            .transition(.blurReplace)
            .animation(.transition, value: title)
            .getRect(textRect, coordSpace: coordSpace) //Inside the padding: the glyphs, not the slot
            .padding(.horizontal, imageHorizontalPadding)
            .padding(.bottom, imageBottomPadding)
    }
}

struct EventImagePagerIndicator: View {
    let imageCount = 6
    let progress: Double
    
    var body: some View {
        ImagePageIndicator(count: 6, progress: progress, activeColor: .white)
            .scaleEffect(0.7, anchor: .bottomTrailing)
            .padding(.horizontal, imageHorizontalPadding)
            .padding(.bottom, imageBottomPadding)
    }
}

struct EventBackButton: View {
    
    //Always mounted, never self-gated: `.eventZoomBandChrome(visible:)` at the call site is the
    //one gate — the page's condition ANDed with the flight's hand-off.
    @Binding var showConfirmScreen: Bool?
    
    var body: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), action: { withAnimation(.transition) { showConfirmScreen = false } }) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .padding(.horizontal, imageHorizontalPadding - 4) //Geometry: as the title — one shared inset from the artwork edge
        .padding(.top, imageTopPadding)
    }
}

struct NewEventToggleButton: View {
    @Binding var responseType: ResponseType
    @Binding var showConfirmScreen: Bool?
    
    private var isNewEvent: Bool { responseType == .newEvent }
    
    var body: some View {
        ScoopButton(style: .clearGlass, shape: .capsule) {
            withAnimation(.dissolve) {
                responseType = isNewEvent ? .originalInvite : .newEvent
                showConfirmScreen = false
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                if !isNewEvent {
                    Image(systemName: "plus")
                        .font(.body(12, .bold))
                }
                
                Text(isNewEvent ? "Original Invite" : "New Invite")
                    .font(.body(11, .bold))
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 7)
            .foregroundStyle(Color.textPrimary)
        }
        .padding()
    }
}

struct OptionsMenu: View {
    //Always mounted, never self-gated: `.eventZoomBandChrome(visible:)` at the call site gates it
    let hasChanges: Bool
    let onClear: () -> Void
    let onDecline: () -> Void

    var body: some View {
        Menu {
            if hasChanges {
                Button(action: onClear) { Label("Clear Invite Draft", image: "BinIcon") }
            }

            Button(role: .destructive, action: onDecline) {
                Label("Decline Profile", systemImage: "xmark")
            }
        } label: {
            HStack(spacing: 3) {
                ForEach(0..<3) { _ in
                    Circle().frame(width: 4, height: 4)
                }
            }
            .foregroundStyle(.white.opacity(0.8))
            .buttonSize(.small)
            .scoopGlassSurface(clear: true, shape: .circle)
            .expandHitArea()
            .padding(.horizontal, imageHorizontalPadding - 4)
            .padding(.top, imageTopPadding)
        }
    }
}
