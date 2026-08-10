//
//  EventLocationMap.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//
import SwiftUI
import MapKit

struct EventLocationMap: View {

    //Injected
    let location: EventLocation
    @Binding var disableMap: Bool
    let openMaps: () -> ()

    //Local view state
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapWidth: CGFloat = 0

    //Measured here, not handed down: the map fills the card it sits in, so its own
    //width is the only honest source for the near-square height.
    private var mapHeight: CGFloat {
        mapWidth > 50 ? mapWidth - 36 : mapWidth
    }

    //Squared-off top, tucked-in bottom; the hit area follows the visible shape.
    private var mapShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: .init(top: CornerRadius.md, bottom: CornerRadius.xs))
    }

    private var defaultCamera: MapCamera {
        MapCamera(centerCoordinate: coord, distance: 1300)
    }

    private var coord: CLLocationCoordinate2D {
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
        .clipShape(mapShape)
        .contentShape(mapShape)
        .frame(maxWidth: .infinity)
        .getWidth($mapWidth)
        .frame(height: max(mapHeight, 0))
        .scaleEffect(disableMap ? 1 : 1.03)
        .overlay(alignment: .bottomTrailing) {
            enableMapButton
        }
        .onAppear {
            cameraPosition = .camera(defaultCamera)
        }
        .animation(.toggle, value: disableMap)
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

extension EventLocationMap {
    private var enableMapButton: some View {
        Button {
            withAnimation(.toggle) {
                disableMap.toggle()
            }
        } label: {
            Text(disableMap ? "Enable Map" : "Disable Map")
                .font(.body(10, .bold))
                .foregroundStyle(Color.textPrimary)
                .padding(.vertical, Spacing.xxs)
                .padding(.horizontal, Spacing.xs)
                .background (
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.appCanvas)
                )
                .contentShape(.rect)
                .padding()
                .padding(Spacing.xxs)
        }
    }
    
}
