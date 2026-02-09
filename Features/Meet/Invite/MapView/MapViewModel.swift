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
    
    
    var categorySearch: String? {
        didSet {
            categorySearchTask?.cancel()
            guard let search = categorySearch?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty else { return }
            results.removeAll()
            categorySearchTask = Task { [weak self] in
                await self?.searchCategoryInVisibleRegion(category: search)
            }
        }
    }

    func searchCategoryInVisibleRegion(category: String) async {
        guard let region = visibleRegion else { return }

        let spec = Self.categorySpec(for: category)
        let plans = [SearchPlan(query: nil, categories: spec.categories)] +
            spec.queries.map { SearchPlan(query: $0, categories: spec.categories) } +
            spec.queries.prefix(2).map { SearchPlan(query: $0, categories: nil) }

        results = await Self.search(region: region, plans: plans)
    }

    func searchInVisibleRegion(query: String) async {
        guard let region = visibleRegion else { return }

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { results = []; return }
        results = await Self.search(region: region, plans: [.init(query: q, categories: nil, pointOfInterestOnly: false)])
    }

    private static func search(region: MKCoordinateRegion, plans: [SearchPlan]) async -> [MKMapItem] {
        let region = searchRegion(region)
        return await withTaskGroup(of: [MKMapItem].self) { group in
            for plan in plans {
                group.addTask {
                    guard !Task.isCancelled else { return [] }
                    let request = MKLocalSearch.Request()
                    request.region = region
                    request.naturalLanguageQuery = plan.query
                    if plan.pointOfInterestOnly { request.resultTypes = .pointOfInterest }
                    if let categories = plan.categories, !categories.isEmpty {
                        request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
                    }
                    return (try? await MKLocalSearch(request: request).start().mapItems) ?? []
                }
            }

            var aggregated: [MKMapItem] = []
            for await items in group {
                aggregated.append(contentsOf: items)
            }
            return deduplicated(aggregated)
        }
    }

    private static func categorySpec(for rawCategory: String) -> (categories: [MKPointOfInterestCategory], queries: [String]) {
        switch rawCategory.lowercased() {
        case "food":
            return ([.restaurant, .foodMarket, .cafe], ["restaurant", "food", "dining", "eat"])
        case "drinks":
            return ([.nightlife, .brewery, .distillery], ["bar", "cocktail", "pub", "drinks"])
        case "cafes", "cafe":
            return ([.cafe], ["cafe", "coffee", "espresso", "tea"])
        default:
            return ([.restaurant, .foodMarket, .cafe, .nightlife, .brewery, .distillery], [rawCategory])
        }
    }

    private static func searchRegion(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        let verticalCoverage: CLLocationDegrees = 0.72
        let minDelta: CLLocationDegrees = 0.002
        let latitudeDelta = max(region.span.latitudeDelta * verticalCoverage, minDelta)
        let longitudeDelta = max(region.span.longitudeDelta, minDelta)
        let centerLatitude = max(min(region.center.latitude + (region.span.latitudeDelta - latitudeDelta) * 0.5, 90), -90)
        return .init(center: .init(latitude: centerLatitude, longitude: region.center.longitude),
                     span: .init(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
    }

    private static func deduplicated(_ items: [MKMapItem]) -> [MKMapItem] {
        var seen = Set<String>()
        return items.filter {
            let coordinate = $0.placemark.coordinate
            let key = "\(normalized($0.name ?? $0.placemark.title ?? ""))|\(Int((coordinate.latitude * 100_000).rounded()))|\(Int((coordinate.longitude * 100_000).rounded()))"
            return seen.insert(key).inserted
        }
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct SearchPlan {
        let query: String?
        let categories: [MKPointOfInterestCategory]?
        let pointOfInterestOnly: Bool

        init(query: String?, categories: [MKPointOfInterestCategory]?, pointOfInterestOnly: Bool = true) {
            self.query = query
            self.categories = categories
            self.pointOfInterestOnly = pointOfInterestOnly
        }
    }
}
