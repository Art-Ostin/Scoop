//
//  PreferredMapsView.swift
//  Scoop
//
//  Created by Art Ostin on 03/05/2026.
//

import SwiftUI

struct PreferredMapView: View {
    
    @Bindable var vm: SettingsViewModel
    
    @State private var showSavedIcon: Bool = false
    @State private var savedIconTask: Task<Void, Never>?
    @State private var showInfoText: Bool = false
    
    var body: some View {
        
        ZStack(alignment: .topTrailing) {
            if showInfoText {
                Text("Preferred maps will show the preferred Maps to click on and send/respond to")
            }
            CustomList(title: "Preferred map", usesContainerWidth: false) {
                HStack {
                    mapOption(mapType: .googleMaps)
                    Spacer()
                    mapOption(mapType: .appleMaps)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            savedAndInfoSection
                .offset(x: -4, y: -4)
        }
    }
}

extension PreferredMapView {
    
    @ViewBuilder
    private var savedAndInfoSection: some View {
        if showSavedIcon {
            SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: true)
        } else {
            infoButton
        }
    }
    
    private var infoButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                showInfoText.toggle()
            }
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(Color.grayPlaceholder)
                .font(.body(12, .medium))
        }
    }
    
    private func mapOption(mapType: PreferredMapType) -> some View {
        let isAppleMaps = mapType == .appleMaps
        var isSelected = mapType == vm.preferredMapType
        
        return Button {
            vm.updatePreferredMapType(mapType)
            isSelected = true
            flashSavedIcon()
        } label: {
            HStack(spacing: 10) {
                Image(isAppleMaps ? "AppleMapIcon" : "GoogleMapsIcon")
                    .opacity(isSelected ? 1 : 0.4)
                Text(isAppleMaps ? "Apple Maps" : "Google Maps")
            }
            .frame(width: 148, height: 44, alignment: .center)
            .font(.body(15, .bold))
            .stroke(20, lineWidth: isSelected ? 0 : 1, color: Color.grayPlaceholder)
            .stroke(20, lineWidth: isSelected ? 1 : 0, color: Color.blue)
            .foregroundStyle(isSelected ? Color.black : Color.grayPlaceholder)
        }
    }
    
    private func flashSavedIcon() {
        savedIconTask?.cancel()
        savedIconTask = Task {
            if showSavedIcon {
                withAnimation(.easeInOut(duration: 0.15)) { showSavedIcon = false }
                try? await Task.sleep(for: .milliseconds(120))
                if Task.isCancelled { return }
            }
            withAnimation(.easeInOut(duration: 0.2)) { showSavedIcon = true }
            try? await Task.sleep(for: .milliseconds(1000))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.2)) { showSavedIcon = false }
        }
    }
}


