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
    
    let title: String
    var isComposeInvite: Bool { title.starts(with: "Invite")}
    
    var body: some View {
        Text(title)
            .font(.title(isComposeInvite ? 22 : 18, .bold))
            .foregroundStyle(Color.white)
            .id(title)
            .transition(.blurReplace)
            .animation(.transition, value: title)
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
    
    //Always mounted so the swap can fade; the container owns the page condition. The scope below
    //is keyed on this value, so this button's OWN fade rides it — but the write carries its own
    //transaction: the card's frame is laid out above that scope, and a scope never reaches up.
    var visible: Bool = true
    @Binding var showConfirmScreen: Bool?
    
    var body: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), action: { withAnimation(.transition) { showConfirmScreen = false } }) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .opacityPop(visible: visible)
        .allowsHitTesting(visible)
        .animation(.transition, value: visible)
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
            responseType = isNewEvent ? .originalInvite : .newEvent
            showConfirmScreen = false
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
            .foregroundStyle(Color.white)
        }
    }
}

struct OptionsMenu: View {
    var visible: Bool = true
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
        .opacityPop(visible: visible)
        .allowsHitTesting(visible)
        .animation(.transition, value: visible)
    }
}
