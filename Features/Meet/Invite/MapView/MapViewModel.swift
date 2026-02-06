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
    var selection: MapSelection<MKMapItem>?
    var selectedMapItem: MKMapItem?

    var visibleRegion: MKCoordinateRegion?
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    func updateSelectedMapItem(from selection: MapSelection<MKMapItem>?) async {
        guard let selection else { selectedMapItem = nil; return }

        if let value = selection.value {
            selectedMapItem = value
            return
        }
        
        guard let feature = selection.feature else { selectedMapItem = nil; return }

        do {
            selectedMapItem = try await MKMapItemRequest(feature: feature).mapItem
        } catch {
            selectedMapItem = nil
        }
    }

    func searchPlaces() async {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = searchText
        let res = try? await MKLocalSearch(request: req).start()
        results = res?.mapItems ?? []
    }

    func searchBarsInVisibleRegion() async {
        guard let region = visibleRegion else { return }

        let req = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        req.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .nightlife,
            .brewery,
            .distillery,
            .winery
        ])
        do {
            results = try await MKLocalSearch(request: req).start().mapItems
        } catch {
            print(error)
        }
    }
}
