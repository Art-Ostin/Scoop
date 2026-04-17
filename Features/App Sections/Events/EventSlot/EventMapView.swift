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
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var coord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: event.location.latitude,
            longitude: event.location.longitude
        )
    }
    
    var body: some View {
        Map(position: $cameraPosition) {
            Marker(event.location.name ?? "", systemImage: "mappin", coordinate: coord)
                .tint(.red)

            UserAnnotation()
                .tint(.blue)
        }
        .tint(.blue)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(width: imageSize, height: imageSize > 50 ? imageSize - 24 : imageSize)
        .allowsHitTesting(!disableMap)
        .overlay(alignment: .bottomTrailing) {
            openInMapsButton(event: event)
        }
        .overlay(alignment: .topTrailing) {
            enableMapButton
        }
        .onAppear {
            cameraPosition = .camera(
                MapCamera(centerCoordinate: coord, distance: 1300)
            )
        }
        .surfaceShadow(.floating, strength: !disableMap  ? 0.6 : 0)
        .onChange(of: disableMap) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.2)) {
                    cameraPosition = .camera(
                        MapCamera(centerCoordinate: coord, distance: 1300)
                    )
                }
            }
        }
    }
}

extension EventMapView {
    
    private var enableMapButton: some View {
        Button {
            disableMap.toggle()
        } label: {
            Text(disableMap ? "Enable Map" : "Disable Map")
                .font(.body(10, .bold))
                .foregroundStyle(Color.black)
                .padding(6)
                .padding(.horizontal, 2)
                .stroke(16, lineWidth: 1, color: .accent)
                .background (
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white).opacity(0.9)
                )
                .contentShape(.rect)
                .padding()
                .padding(4)
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
