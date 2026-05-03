//
//  PreferredMapsView.swift
//  Scoop
//
//  Created by Art Ostin on 03/05/2026.
//

import SwiftUI

struct PreferredMapView: View {
    
    @Bindable var vm: SettingsViewModel
    
    @Namespace private var savedToIconTransition
    
    @State private var showSavedIcon: Bool = false
    @State private var isFlashing: Bool = false
    @State private var savedIconTask: Task<Void, Never>?
    @State private var showInfoText: Bool = false
    
    var body: some View {
        
        ZStack(alignment: .topTrailing) {
            
            CustomList(title: "Preferred Maps", usesContainerWidth: false, showInfoText: showInfoText) {
                HStack {
                    mapOption(mapType: .googleMaps)
                    Spacer()
                    mapOption(mapType: .appleMaps)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            savedAndInfoSection
                .offset(x: -4, y: showSavedIcon ? -6 : -4)
        }
    }
}

extension PreferredMapView {
    
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
            withAnimation(.easeInOut(duration: 0.3)) {
                showInfoText.toggle()
            }
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(Color(red: 0.8, green: 0.8, blue: 0.8))
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
        isFlashing = true
        savedIconTask = Task {
            if showSavedIcon {
                withAnimation(.easeInOut(duration: 0.15)) { showSavedIcon = false }
                try? await Task.sleep(for: .milliseconds(120))
                if Task.isCancelled { return }
            }
            withAnimation(.easeInOut(duration: 0.2)) { showSavedIcon = true }
            try? await Task.sleep(for: .milliseconds(1000))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                showSavedIcon = false
                isFlashing = false
            }
        }
    }
}


