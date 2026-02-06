//
//  MapViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//
import SwiftUI
import MapKit

@MainActor
@Observable class MapViewModel {

    let locationManager = CLLocationManager()

    var searchText: String = ""
    var results: [MKMapItem] = []
    var lookAroundScene: MKLookAroundScene?

    var selection: MapSelection<MKMapItem>?

    // Keep these updated from onMapCameraChange
    var currentSpan: MKCoordinateSpan = .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
    var visibleRegion: MKCoordinateRegion?
    var currentCamera: MapCamera?

    // Camera animation “inputs” for the Map view
    var cameraAnimationTrigger: Int = 0
    var cameraTarget: MapCamera?
    var cameraAnimationDuration: Double = 0.85

    var selectedMapItem: MKMapItem? {
        didSet { planCameraMove(to: selectedMapItem) }
    }

    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    func updateSelectedMapItem(from selection: MapSelection<MKMapItem>?) async {
        guard let selection else { selectedMapItem = nil; return }

        if let value = selection.value {
            selectedMapItem = value
            return
        }

        guard let feature = selection.feature else { selectedMapItem = nil; return }

        do {
            let request = MKMapItemRequest(feature: feature)
            selectedMapItem = try await request.mapItem
        } catch {
            selectedMapItem = nil
        }
    }

    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let response = try? await MKLocalSearch(request: request).start()
        self.results = response?.mapItems ?? []
    }

    func searchBarsInVisibleRegion() async {
        guard let region = visibleRegion else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "bar"
        request.region = region
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.nightlife])

        do {
            let response = try await MKLocalSearch(request: request).start()
            self.results = response.mapItems
        } catch {
            print(error)
        }
    }

    private func planCameraMove(to mapItem: MKMapItem?) {
        guard let item = mapItem else {
            cameraTarget = nil
            return
        }

        let coord = item.placemark.coordinate
        let yOffset = currentSpan.latitudeDelta * 0.15
        let targetCenter = CLLocationCoordinate2D(
            latitude: coord.latitude - yOffset,
            longitude: coord.longitude
        )

        let base = currentCamera ?? cameraPosition.camera ?? MapCamera(
            centerCoordinate: targetCenter,
            distance: 2500,
            heading: 0,
            pitch: 0
        )

        cameraTarget = MapCamera(
            centerCoordinate: targetCenter,
            distance: base.distance,
            heading: base.heading,
            pitch: base.pitch
        )

        // Longer when zoomed in (small distance) so it doesn’t “snap”
        cameraAnimationDuration = duration(forDistance: base.distance)

        cameraAnimationTrigger &+= 1
    }

    private func duration(forDistance d: CLLocationDistance) -> Double {
        let minD: Double = 800
        let maxD: Double = 30_000
        let clamped = min(max(d, minD), maxD)
        let t = (maxD - clamped) / (maxD - minD)   // zoomed-in => larger t
        return 0.45 + 0.55 * t                      // 0.45 … 1.0
    }
}
