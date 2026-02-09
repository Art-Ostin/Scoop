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
            categorySearchTask = Task { [weak self] in
                await self?.searchCategory(category: search)
            }
        }
    }

    func searchCategory(category: String) async {
        guard let region = visibleRegion else { return }
        let spec = Self.categorySpec(for: category) //Get the specifics to search
        let plans = [SearchPlan(query: nil, categories: spec.categories)] +
            spec.queries.map { SearchPlan(query: $0, categories: spec.categories) } +
            spec.queries.prefix(2).map { SearchPlan(query: $0, categories: nil) }
        results = await Self.search(region: region, plans: plans)
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
    
    private static func search(region: MKCoordinateRegion, plans: [SearchPlan]) async -> [MKMapItem] {
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
