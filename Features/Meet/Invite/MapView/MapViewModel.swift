//
//  MapViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.

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
    private var categorySearchTask: Task<Void, Never>?

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
    
    
    var categorySearchText: String? {
        didSet {
            categorySearchTask?.cancel()
            guard let search = categorySearchText?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty else { return }
            results.removeAll()
            categorySearchTask = Task {
                await searchCategory(category: search)
            }
        }
    }

    func searchCategory(category: String) async {
        guard let region = visibleRegion ?? cameraPosition.region else { return }
        let spec = Self.categorySpec(for: category)

        let request = MKLocalSearch.Request()
        request.region = region
        request.resultTypes = .pointOfInterest
        request.naturalLanguageQuery = spec.query
        if !spec.categories.isEmpty {
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: spec.categories)
        }

        let items = (try? await MKLocalSearch(request: request).start().mapItems) ?? []
        guard !Task.isCancelled else { return }
        results = items
    }
    
    private static func categorySpec(for rawCategory: String) -> (categories: [MKPointOfInterestCategory], query: String?) {
        switch rawCategory.lowercased() {
        case "food":
            return ([.restaurant, .foodMarket, .cafe], nil)
        case "drinks":
            return ([.nightlife, .brewery, .distillery], nil)
        case "cafes", "cafe":
            return ([.cafe], nil)
        default:
            return ([.restaurant, .foodMarket, .cafe, .nightlife, .brewery, .distillery], rawCategory)
        }
    }
}
