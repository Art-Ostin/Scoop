//
//  EventImageOverlays.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

//Overlays
struct EventTitle: View {
    let title: String
    
    var showInfo: (() -> ())?
    
    var isComposeInvite: Bool { showInfo != nil }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.title(isComposeInvite ? 22 : 18, .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20) //Geometry: the invite card's own title inset from the artwork edge
                .padding(.bottom, Spacing.sm)
            
            if isComposeInvite {
                Image(systemName: "info.circle")
                    .font(.body(14, .medium))
                    .foregroundStyle(Color.white)
                    .padding(Spacing.xs) //the 8pt gap doubles as the hit ring
                    .contentShape(Rectangle()) //PressButtonStyle sets none — without it the ring misses
            }
        }
        .shrinkPress { showInfo?() }
    }
}

struct EventImagePagerIndicator: View {
    let imageCount = 6
    let progress: Double
    
    var body: some View {
        ImagePageIndicator(count: 6, progress: progress, activeColor: .white)
            .scaleEffect(0.7, anchor: .trailing)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xs)
    }
}

struct EventBackButton: View {
    
    @Binding var showConfirmScreen: Bool?
    
    var body: some View {
        
        ScoopButton(style: .clearGlass, shape: Circle(), action: { showConfirmScreen = false }) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .padding(.horizontal, 20) //Geometry: as the title — one shared inset from the artwork edge
        .padding(.top, Spacing.sm)
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
        }
    }
}
