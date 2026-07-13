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
    let imageSize: CGFloat
    @Binding var disableMap: Bool
    let openMaps: () -> ()

    //Local view state
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var mapHeight: CGFloat {
        imageSize > 50 ? imageSize - 36 : imageSize
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
        .frame(width: max(imageSize, 0), height: max(mapHeight, 0))
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
