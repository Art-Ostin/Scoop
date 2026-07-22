//
//  PreferredMapsView.swift
//  Scoop
//
//  Created by Art Ostin on 03/05/2026.
//

import SwiftUI

struct PreferredMapsView: View {
    
    //Injected
    @Bindable var vm: SettingsViewModel

    //Local view state
    @State private var showSavedIcon: Bool = false
    @State private var showInfoText: Bool = false
    @Namespace private var savedToIconTransition
    
    var body: some View {
        
        ZStack(alignment: .topTrailing) {
            savedAndInfoSection
                .offset(x: -4, y: showSavedIcon ? -6 : -4)

            CustomList(title: "Preferred Maps", showInfoText: showInfoText) {
                HStack {
                    mapOption(mapType: .googleMaps)
                    Spacer()
                    mapOption(mapType: .appleMaps)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
            }
        }
        .savedFeedback(
            isPresented: $showSavedIcon,
            tracking: vm.preferredMapType,
            animation: .transition
        )
    }
}

extension PreferredMapsView {
    
    @ViewBuilder
    private var savedAndInfoSection: some View {
        
        ZStack(alignment: .topTrailing) {
            if showSavedIcon {
                SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: true)
                    .matchedGeometryEffect(id: "icon", in: savedToIconTransition, properties: .position)
                    .transition(.opacity)
            } else {
                infoButton
                    .matchedGeometryEffect(id: "icon", in: savedToIconTransition, properties: .position)
                    .transition(.opacity)
            }
        }
    }
    
    private var infoButton: some View {
        Button {
            withAnimation(.expand) {
                showInfoText.toggle()
            }
        } label: {
            SmallInfoIcon()
        }
    }
    
    
    private func mapOption(mapType: PreferredMapType) -> some View {
        let isAppleMaps = mapType == .appleMaps
        let isSelected = mapType == vm.preferredMapType

        return Button {
            vm.updatePreferredMapType(mapType)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(isAppleMaps ? "AppleMapIcon" : "GoogleMapsIcon")
                    .opacity(isSelected ? 1 : 0.4)
                Text(isAppleMaps ? "Apple Maps" : "Google Maps")
            }
            .frame(width: 148, height: 44, alignment: .center)
            .font(.body(15, .bold))
            .capsuleStroke(lineWidth: isSelected ? 0 : 1, color: Color.border)
            .capsuleStroke(lineWidth: isSelected ? 1 : 0, color: Color.accent)
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textPlaceholder)
        }
    }
    
}
