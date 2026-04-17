//
//  EventMapView.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI
import MapKit

struct EventMapView: View {
    
    let event: UserEvent
    let imageSize: CGFloat
    @Binding var disableMap: Bool
    let openMaps: () -> ()
    
    var coord: CLLocationCoordinate2D  {
        CLLocationCoordinate2D(latitude: event.location.latitude, longitude: event.location .longitude)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(initialPosition: .camera(.init(centerCoordinate: coord, distance: 800))) {
                Marker(event.location.name ?? "",systemImage: "mappin", coordinate: coord)
                    .tint(.red)
                
                UserAnnotation()
                    .tint(.blue)
            }
            .tint(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .frame(width: imageSize, height: imageSize > 50 ? imageSize - 24 : imageSize)
            .disabled(disableMap)
            
            openInMapsButton(event: event)
        }
    }
}

extension EventMapView {
    
    
    private var enableMapButton: some View {
        Button {
            
        } label: {
            Text("Enable Map")
                .font(.body(14, .bold))
        }
    }
    
    
    
    private func openInMapsButton(event: UserEvent) -> some View {
        Button {
            openMaps()
        } label: {
            Text("Open Maps")
                .font(.custom("SFProRounded-Semibold", size: 14))
                .foregroundStyle(Color.black)
                .opacity(0.6)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .underline()
        }
    }
}

/*
 HStack(spacing: 6) {
     Image(systemName: "map")
         .font(.body(14, .bold))
     
     Text("Open Maps")
         .foregroundStyle(Color.blue)
         .font(.body(12, .bold))
 }
 .padding(.horizontal, 8)
 .tint(.blue)
 .padding(.vertical, 6)
 .glassIfAvailable()
 .padding(.horizontal)
 .padding(.vertical, 10)

 */
