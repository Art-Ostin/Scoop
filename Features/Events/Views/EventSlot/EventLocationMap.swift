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

    //Local view state
    @State private var cameraPosition: MapCameraPosition = .automatic

    //Squared-off top, tucked-in bottom; the hit area follows the visible shape.
    private var mapShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: .init(top: CornerRadius.lg, bottom: 0))
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
        //Shaped by the card, not by measuring itself: the card hands down the width,
        //the ratio sets the height. fixedSize keeps a squeezed proposal from narrowing it.
        Color.clear
            .aspectRatio(AspectRatio.eventLocationMap.ratio, contentMode: .fit)
            .fixedSize(horizontal: false, vertical: true)
            .overlay {
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
                    withAnimation(.move) {
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
