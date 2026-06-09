//
//  EventMapView.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//
import SwiftUI
import MapKit

struct EventMapView: View {

    
    let location: EventLocation


    let imageSize: CGFloat
    @Binding var disableMap: Bool
    let openMaps: () -> ()
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    private let toggleAnimation = Animation.easeInOut(duration: 0.2)
    
    private var mapHeight: CGFloat {
        imageSize > 50 ? imageSize - 36 : imageSize
    }
    
    private var defaultCamera: MapCamera {
        MapCamera(centerCoordinate: coord, distance: 1300)
    }
    
    var coord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
    }
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                Marker(location.name ?? "", systemImage: "mappin", coordinate: coord)
                    .tint(.red)
                
                UserAnnotation()
                    .tint(.blue)
            }
            .allowsHitTesting(!disableMap)
        }
        .tint(.blue)
        .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(width: max(imageSize, 0), height: max(mapHeight, 0))
        .scaleEffect(disableMap ? 1 : 1.03)
        .overlay(alignment: .bottomTrailing) {
            enableMapButton
        }
        .onAppear {
            cameraPosition = .camera(defaultCamera)
        }
        .animation(toggleAnimation, value: disableMap)
        .task(id: disableMap) {
            guard disableMap else { return }
            await Task.yield()
            guard disableMap else { return }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.45)) {
                    cameraPosition = .camera(defaultCamera)
                }
            }
        }
    }
}

extension EventMapView {
    private var enableMapButton: some View {
        Button {
            if disableMap == true {
                //1. Slow animation to the mapViw
//                withAnimation(.easeInOut(duration: 1)) {
//                    proxy.scrollTo("MapsView", anchor: .center)
//                }
            }
            withAnimation(toggleAnimation) {
                disableMap.toggle()
            }
        } label: {
            Text(disableMap ? "Enable Map" : "Disable Map")
                .font(.body(10, .bold))
                .foregroundStyle(Color.black)
                .padding(6)
                .padding(.horizontal, 2)
                .background (
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCanvas)
                )
                .contentShape(.rect)
                .padding()
                .padding(4)
        }
    }
    
}
