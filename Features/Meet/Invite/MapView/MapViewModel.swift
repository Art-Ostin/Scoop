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
            guard let search = categorySearch?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !search.isEmpty else { return }

            categorySearchTask = Task { [weak self] in
                await self?.searchCategoryInVisibleRegion(category: search)
            }
        }
    }

    func searchCategoryInVisibleRegion(category: String) async {
        guard let region = visibleRegion else { return }

        let strategy = Self.categorySearchStrategy(for: category)
        let filteredQueries: [String?] = [nil] + strategy.queries.map { Optional($0) }
        var aggregated = await Self.runCategorySearches(
            region: region,
            categories: strategy.categories,
            queries: filteredQueries
        )

        if aggregated.count < strategy.minimumResultsForFilteredSearch {
            let fallbackQueries = strategy.queries.prefix(2).map { Optional($0) }
            let fallbackResults = await Self.runCategorySearches(
                region: region,
                categories: nil,
                queries: fallbackQueries
            )
            aggregated.append(contentsOf: fallbackResults)
        }

        guard !Task.isCancelled else { return }
        results = Self.deduplicated(aggregated)
    }

    func searchInVisibleRegion(query: String) async {
        guard let region = visibleRegion else { return }

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q
        request.region = region
        do {
            results = try await MKLocalSearch(request: request).start().mapItems
        } catch {
            print("Local search error:", error)
        }
    }

    private static func runCategorySearch(
        region: MKCoordinateRegion,
        query: String?,
        categories: [MKPointOfInterestCategory]?
    ) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.region = expandedRegion(region)
        request.resultTypes = .pointOfInterest
        if let categories, !categories.isEmpty {
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
        }
        request.naturalLanguageQuery = query
        return try await MKLocalSearch(request: request).start().mapItems
    }

    private static func runCategorySearches(
        region: MKCoordinateRegion,
        categories: [MKPointOfInterestCategory]?,
        queries: [String?]
    ) async -> [MKMapItem] {
        await withTaskGroup(of: [MKMapItem].self) { group in
            for query in queries {
                group.addTask {
                    guard !Task.isCancelled else { return [] }
                    do {
                        return try await runCategorySearch(region: region, query: query, categories: categories)
                    } catch {
                        return []
                    }
                }
            }

            var aggregated: [MKMapItem] = []
            for await items in group {
                aggregated.append(contentsOf: items)
            }
            return aggregated
        }
    }

    private static func categorySearchStrategy(for rawCategory: String) -> CategorySearchStrategy {
        switch rawCategory.lowercased() {
        case "food":
            return .init(
                categories: [.restaurant, .foodMarket, .cafe],
                queries: ["restaurant", "food", "dining", "eat"],
                minimumResultsForFilteredSearch: 12
            )
        case "drinks":
            return .init(
                categories: [.nightlife, .brewery, .distillery],
                queries: ["bar", "cocktail", "pub", "drinks"],
                minimumResultsForFilteredSearch: 10
            )
        case "cafes", "cafe":
            return .init(
                categories: [.cafe],
                queries: ["cafe", "coffee", "espresso", "tea"],
                minimumResultsForFilteredSearch: 8
            )
        default:
            return .init(
                categories: [.restaurant, .foodMarket, .cafe, .nightlife, .brewery, .distillery],
                queries: [rawCategory],
                minimumResultsForFilteredSearch: 8
            )
        }
    }

    private static func expandedRegion(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        let verticalCoverage: CLLocationDegrees = 0.72
           let horizontalCoverage: CLLocationDegrees = 1.0
           let minDelta: CLLocationDegrees = 0.002

           let latitudeDelta = Swift.min(Swift.max(region.span.latitudeDelta * verticalCoverage, minDelta), 180)
           let longitudeDelta = Swift.min(Swift.max(region.span.longitudeDelta * horizontalCoverage, minDelta), 360)
           let northShift = (region.span.latitudeDelta - latitudeDelta) * 0.5
           let centeredLatitude = Swift.max(Swift.min(region.center.latitude + northShift, 90), -90)

           return .init(
               center: .init(latitude: centeredLatitude, longitude: region.center.longitude),
               span: .init(
                   latitudeDelta: latitudeDelta,
                   longitudeDelta: longitudeDelta
               )
           )
    }

    private static func deduplicated(_ items: [MKMapItem]) -> [MKMapItem] {
        var seen = Set<MapItemKey>()
        var unique: [MKMapItem] = []

        for item in items {
            let key = mapItemKey(for: item)
            if seen.insert(key).inserted {
                unique.append(item)
            }
        }
        return unique
    }

    private static func mapItemKey(for item: MKMapItem) -> MapItemKey {
        let coordinate = item.placemark.coordinate
        return .init(
            name: normalized(item.name ?? item.placemark.title ?? ""),
            latitudeBucket: coordinateBucket(for: coordinate.latitude),
            longitudeBucket: coordinateBucket(for: coordinate.longitude),
            street: normalized(item.placemark.thoroughfare ?? ""),
            number: normalized(item.placemark.subThoroughfare ?? ""),
            city: normalized(item.placemark.locality ?? ""),
            postalCode: normalized(item.placemark.postalCode ?? "")
        )
    }

    private static func coordinateBucket(for value: CLLocationDegrees) -> Int {
        Int((value * 100_000).rounded())
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)


    }

    private struct CategorySearchStrategy {
        let categories: [MKPointOfInterestCategory]
        let queries: [String]
        let minimumResultsForFilteredSearch: Int
    }
    
    private struct MapItemKey: Hashable {
        let name: String
        let latitudeBucket: Int
        let longitudeBucket: Int
        let street: String
        let number: String
        let city: String
        let postalCode: String
    }
}
