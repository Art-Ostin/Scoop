//
//  MapViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.

import SwiftUI
import MapKit
import UIKit


@MainActor
@Observable class MapViewModel {

    let locationManager = CLLocationManager()
    private static let minimumPlaceCount = 25
    private static let searchRegionScaleSteps: [CLLocationDegrees] = [1.0, 1.8, 3.2, 5.6, 10.0, 18.0]
    var searchText: String = ""
    var results: [MKMapItem] = []
    var selection: MapSelection<MKMapItem>?
    var selectedMapItem: MKMapItem?

    var visibleRegion: MKCoordinateRegion?
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    private var categorySearchTask: Task<Void, Never>?
    
    var markerTint: Color {
        selectedMapCategory?.mainColor ?? Color.appColorTint
    }

    var selectedMapCategory: MapIconStyle? {
        didSet {onCategorySelect()}
    }
    
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
        guard let region = visibleRegion else {
            results = []
            return
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        results = await Self.searchWithExpandedRegions(from: region, minimumCount: Self.minimumPlaceCount) { searchRegion in
            let request = MKLocalSearch.Request()
            request.region = searchRegion
            request.naturalLanguageQuery = query
            let items = (try? await MKLocalSearch(request: request).start().mapItems) ?? []
            return Self.items(in: searchRegion, from: items)
        }
    }
    
    private func onCategorySelect() {
        if let category = selectedMapCategory {
            categorySearchTask?.cancel()
            categorySearchTask = Task { [weak self] in
                await self?.searchCategory(category: category.description)
            }
        } else {
            //If set to nil remove all the values
            results.removeAll()
        }
    }
    
    private func searchCategory(category: String) async {
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
        return await searchWithExpandedRegions(from: region, minimumCount: minimumPlaceCount) { searchRegion in
            await withTaskGroup(of: [MKMapItem].self) { group in
                for plan in plans {
                    group.addTask {
                        guard !Task.isCancelled else { return [] }
                        let request = MKLocalSearch.Request()
                        request.region = searchRegion
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
                let deduped = deduplicated(aggregated)
                return items(in: searchRegion, from: deduped)
            }
        }
    }

    private static func searchWithExpandedRegions(
        from baseRegion: MKCoordinateRegion,
        minimumCount: Int,
        search: (MKCoordinateRegion) async -> [MKMapItem]
    ) async -> [MKMapItem] {
        var aggregated: [MKMapItem] = []
        for scale in searchRegionScaleSteps {
            guard !Task.isCancelled else { break }
            let searchRegion = scaledRegion(baseRegion, by: scale)
            let items = await search(searchRegion)
            aggregated = deduplicated(aggregated + items)
            if aggregated.count >= minimumCount {
                break
            }
        }
        return aggregated
    }

    private static func scaledRegion(_ region: MKCoordinateRegion, by scale: CLLocationDegrees) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: min(region.span.latitudeDelta * scale, 180),
                longitudeDelta: min(region.span.longitudeDelta * scale, 360)
            )
        )
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
    
    private static func items(in region: MKCoordinateRegion, from items: [MKMapItem]) -> [MKMapItem] {
         items.filter { contains($0.placemark.coordinate, in: region) }
     }

    private static func contains(_ coordinate: CLLocationCoordinate2D, in region: MKCoordinateRegion) -> Bool {
        let halfLatitude = region.span.latitudeDelta / 2
        let maximumLatitude = region.center.latitude + halfLatitude
        let searchableHeight = region.span.latitudeDelta * 0.75
        let searchableMinimumLatitude = maximumLatitude - searchableHeight
        guard coordinate.latitude >= searchableMinimumLatitude && coordinate.latitude <= maximumLatitude else { return false }

        let halfLongitude = region.span.longitudeDelta / 2
        let longitudeDifference = normalizedLongitude(coordinate.longitude - region.center.longitude)
        return abs(longitudeDifference) <= halfLongitude
    }

    private static func normalizedLongitude(_ longitude: CLLocationDegrees) -> CLLocationDegrees {
        var value = longitude.truncatingRemainder(dividingBy: 360)
        if value > 180 { value -= 360 }
        if value < -180 { value += 360 }
        return value
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


/* // Come back to
 func searchPlaces() async {
     let req = MKLocalSearch.Request()
     req.naturalLanguageQuery = searchText
     let res = try? await MKLocalSearch(request: req).start()
     results = res?.mapItems ?? []
 }
 
 */

/*
 var categorySearchText: String? {
     didSet {
         categorySearchTask?.cancel()
         guard let search = categorySearchText?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty else { return }
         categorySearchTask = Task { [weak self] in
             await self?.searchCategory(category: search)
         }
     }
 }

 */


/*
 
 categorySearchText = selectedMapCategory.description
 categorySearchTask?.cancel()
 guard let search = categorySearchText?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty else { return }
 categorySearchTask = Task { [weak self] in
     await self?.searchCategory(category: search)
 }

 */
