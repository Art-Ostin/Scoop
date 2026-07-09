//
//  EventMap.swift
//  Scoop
//
//  Created by Art Ostin on 09/06/2026.
//

import SwiftUI
import MapKit

struct EventMap: View {
    let location: EventLocation
    let imageSize: CGFloat
    @Binding var disableMap: Bool
    let openMaps: () -> ()
    
    var body: some View {
        VStack(spacing: 12) {
            EventLocationMap(location: location, imageSize: imageSize, disableMap: $disableMap, openMaps: openMaps)
            locationInfo
        }
        .padding([.horizontal, .top], 4)
        .padding(.bottom, 16)
        .stroke(CornerRadius.md, lineWidth: disableMap ? 1 : 0, color: Color.border)
        .customShadow(.floating, strength: !disableMap  ? 0.6 : 0)
        .eventCardShadowBackground()
    }
}

extension EventMap {

    private var locationInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            locationTextSection
            locationButtonSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var locationTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(location.name ?? "")
                    .font(.body(19, .bold))
                Spacer()
                Text("1.3km")
                    .font(.body(15, .bold))
            }
            .foregroundStyle(Color.textPrimary)
            
            Text("Nightclub")   // update later so actually shows location
                .font(.body(15, .regular))
                .foregroundStyle(Color.textPrimary)
            
            if let category = location.mapItem.pointOfInterestCategory {
                
            }
            
            Text(location.address ?? "")
                .font(.body(15, .regular))
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    private var locationButtonSection: some View {
        HStack {
            locationIcon(text: "7 min", icon: "EventCarIcon", isMap: false)
            Spacer()
            locationIcon(text: "23 min", icon: "EventWalkIcon", isMap: false)
            Spacer()
            locationIcon(text: "Maps", icon: "EventMapsIcon", isMap: true)
        }
    }
    
    private func locationIcon(text: String, icon: String, isMap: Bool) -> some View {
        VStack(spacing: 0) {
            Image(icon)
            
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .frame(width: 75, height: 40)
        .background(Color.white, in: .rect(cornerRadius: CornerRadius.sm))
        .stroke(CornerRadius.sm, lineWidth: 1, color: isMap ? Color.accent : Color.border)
    }
}
