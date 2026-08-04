//
//  MapViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2025.

import SwiftUI
import MapKit
import UIKit


@MainActor
@Observable class MapViewModel {
    
    let defaults: DefaultsManaging

    let locationManager = CLLocationManager()
    var searchText: String = ""
    var results: [MKMapItem] = []
    var selection: MapSelection<MKMapItem>? {
        didSet {
            showAnimation = oldValue != nil && selection != nil
        }
    }
    var selectedMapItem: MKMapItem? {
        didSet {
            showAnimation = oldValue != nil && selection != nil
        }
    }
    
    var visibleRegion: MKCoordinateRegion?
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    private var categorySearchTask: Task<Void, Never>?
    private var categorySelectionFromSearchArea = false
    
    var showAnimation = false
    
    var markerTint: Color = Color.accent
    
    
    var selectedMapCategory: MapCategory? {
        didSet {onCategorySelect()}
    }
    
    var lastSearchRegion: MKCoordinateRegion?
    //Where the auto-flight lands: the nearest pin's distance from the search origin. Panning
    //past it by more than the slack flips the icon to "Search Area".
    private var lastLandingDistance: CLLocationDistance = 0

    //Set when a search auto-selects its nearest result, so the camera flies back to a readable zoom.
    var lastSelectionWasAutomatic = false

    //Set when a search lands with zero results, so the sheet can say so instead of spinning forever.
    var searchFoundNothing = false

    //Monotonic stamp: an async search must present the current stamp to write state, so a superseded
    //search that resumes late can never overwrite a newer one.
    private var searchGeneration = 0

    var recentMapSearches: [RecentPlace]
    
    
    init(defaults: DefaultsManaging) {
        self.defaults = defaults
        self.recentMapSearches = defaults.recentMapSearches
    }
    
    func updateSelectedMapItem(from selection: MapSelection<MKMapItem>?) async {
        guard let selection else {
            selectedMapItem = nil
            return
        }
        
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
    
    //Returns false when a newer search superseded this one — callers must not act on the results.
    @discardableResult
    func searchPlaces() async -> Bool {
        searchGeneration += 1
        let generation = searchGeneration
        searchFoundNothing = false

        if let selectedMapCategory {
            await searchCategory(category: selectedMapCategory, query: searchText, generation: generation)
            //Found-nothing also returns false: results hold nothing (or a previous search) to act on.
            return generation == searchGeneration && !searchFoundNothing
        }

        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = searchText
        if let visibleRegion { req.region = visibleRegion } //Bias, not a boundary: a typed search may leave the area
        let res = try? await MKLocalSearch(request: req).start()
        guard generation == searchGeneration else { return false }
        results = res?.mapItems ?? []
        searchFoundNothing = results.isEmpty
        return true
    }

    func selectCategory(_ category: MapCategory, fromSearchArea: Bool = false) {
        categorySelectionFromSearchArea = fromSearchArea
        selectedMapCategory = category
    }

    //The search bar's xmark: drops the query and any selected category.
    func clearSearch() {
        guard selectedMapCategory != nil else {
            categorySearchTask?.cancel()
            resetSearchState()
            return
        }
        selectedMapCategory = nil //didSet → onCategorySelect() cancels the task and resets
    }

    private func onCategorySelect() {
        categorySearchTask?.cancel()
        let fromSearchArea = categorySelectionFromSearchArea
        categorySelectionFromSearchArea = false

        if let category = selectedMapCategory {
            searchGeneration += 1
            let generation = searchGeneration
            searchFoundNothing = false
            categorySearchTask = Task { [weak self] in
                await self?.searchCategory(category: category, query: nil, fromSearchArea: fromSearchArea, generation: generation)
                guard let self, generation == self.searchGeneration else { return }
                self.searchText = category.description
                self.markerTint = category.mainColor
            }
        } else {
            //If categorySelect set to nil, delete all the existing values
            resetSearchState()
        }
    }

    private func resetSearchState() {
        searchGeneration += 1 //Invalidates any in-flight search so it can't resurrect the cleared state
        results.removeAll()
        searchText = ""
        markerTint = .accent
        searchFoundNothing = false
        lastSelectionWasAutomatic = false
    }
    
    //Search and assign all the categories
    private func searchCategory(category: MapCategory, query: String?, fromSearchArea: Bool = false, generation: Int) async {
        guard let scope = searchScope(fromSearchArea: fromSearchArea) else {
            if generation == searchGeneration { searchFoundNothing = true }
            return
        }
        let spec = Self.categorySpec(category: category)
        let plans = Self.makeSearchPlans(from: spec, with: query)
        let foundItems = await Self.search(region: scope.region, plans: plans)
        guard generation == searchGeneration else { return }
        let matches = Self.applyCategoryFilter(foundItems, spec: spec)
        let found = Self.nearestResults(matches, scope: scope)
        results = found.items
        lastSearchRegion = scope.region
        lastLandingDistance = found.landing
        searchFoundNothing = results.isEmpty
        if let nearest = results.first {
            //Only flag when the selection will actually change — an equal value never fires onChange,
            //and an unconsumed flag would clamp the next manual pin tap.
            lastSelectionWasAutomatic = MapSelection(nearest) != selection
            selection = MapSelection(nearest)
        }
    }

    private static let nearbyRadius: CLLocationDistance = 2500
    private static let searchAreaMinRadius: CLLocationDistance = 1500
    private static let maxCategoryResults = 20
    private static let radiusTolerance = 1.2
    private static let searchAreaSlack: CLLocationDistance = 800

    //Where a category search anchors: the user's surroundings normally, the panned-to area for "Search Area".
    private struct SearchScope {
        let origin: CLLocationCoordinate2D
        let region: MKCoordinateRegion
        let radius: CLLocationDistance
    }

    private func searchScope(fromSearchArea: Bool) -> SearchScope? {
        if fromSearchArea, let region = visibleRegion {
            let rawRadius = Self.regionRadius(region)
            if rawRadius >= Self.searchAreaMinRadius {
                return SearchScope(origin: region.center, region: region, radius: rawRadius)
            }
            //Zoomed-in viewports widen to the minimum reach — the .required boundary must match the filter.
            let widened = MKCoordinateRegion(center: region.center,
                                             latitudinalMeters: Self.searchAreaMinRadius * 2,
                                             longitudinalMeters: Self.searchAreaMinRadius * 2)
            return SearchScope(origin: region.center, region: widened, radius: Self.searchAreaMinRadius)
        }
        guard let origin = preferredSelectionOrigin() else { return nil }
        let region = MKCoordinateRegion(center: origin, latitudinalMeters: Self.nearbyRadius * 2, longitudinalMeters: Self.nearbyRadius * 2)
        return SearchScope(origin: origin, region: region, radius: Self.nearbyRadius)
    }

    private static func regionRadius(_ region: MKCoordinateRegion) -> CLLocationDistance {
        let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let edge = CLLocation(latitude: region.center.latitude + region.span.latitudeDelta / 2,
                              longitude: region.center.longitude + region.span.longitudeDelta / 2)
        return center.distance(from: edge)
    }

    //Nearest-first and hard-capped, so every pin stays within reach and the map stays readable.
    //Also reports where the auto-selection will land: the nearest kept pin's distance (0 when nothing survived).
    private static func nearestResults(_ items: [MKMapItem], scope: SearchScope) -> (items: [MKMapItem], landing: CLLocationDistance) {
        let origin = CLLocation(latitude: scope.origin.latitude, longitude: scope.origin.longitude)
        let maxDistance = scope.radius * radiusTolerance
        let kept = items
            .map { item -> (item: MKMapItem, distance: CLLocationDistance) in
                let coordinate = item.placemark.coordinate
                return (item, origin.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)))
            }
            .filter { $0.distance <= maxDistance }
            .sorted { $0.distance < $1.distance }
            .prefix(maxCategoryResults)
        return (kept.map(\.item), kept.first?.distance ?? 0)
    }

    private func preferredSelectionOrigin() -> CLLocationCoordinate2D? {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if let coordinate = locationManager.location?.coordinate {
                return coordinate
            }
            return visibleRegion?.center
        default:
            return visibleRegion?.center
        }
    }

    private static func search(region: MKCoordinateRegion, plans: [SearchPlan]) async -> [MKMapItem] {
        
        return await withTaskGroup(of: [MKMapItem].self) { group in
                for plan in plans {
                    group.addTask {
                        guard !Task.isCancelled else { return [] }
                        let request = MKLocalSearch.Request()
                        request.region = region
                        request.regionPriority = .required //iOS 18: makes the region a boundary instead of a hint
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
                return deduped
            }
        }
    
    //Helps Identify equivalency and avoid duplicates
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

    private static func makeSearchPlans(from spec: CategorySpec, with query: String?) -> [SearchPlan] {
        var plans: [SearchPlan] = []
        if !spec.categories.isEmpty {
            plans.append(SearchPlan(query: nil, categories: spec.categories))
            plans += deduplicateQueries(spec.queries).map { SearchPlan(query: $0, categories: spec.categories) }
        }
        plans += deduplicateQueries(spec.unfilteredQueries).map { SearchPlan(query: $0, categories: nil) }

        //A user-typed query runs both with and without the POI filter so uncategorized places can still match.
        if let query, !normalized(query).isEmpty {
            if !spec.categories.isEmpty { plans.insert(SearchPlan(query: query, categories: spec.categories), at: 0) }
            plans.append(SearchPlan(query: query, categories: nil))
        }
        return plans
    }

    private static func deduplicateQueries(_ queries: [String]) -> [String] {
        var seen = Set<String>()
        var deduplicated: [String] = []

        for query in queries {
            let normalizedQuery = normalized(query)
            guard !normalizedQuery.isEmpty else { continue }
            if seen.insert(normalizedQuery).inserted {
                deduplicated.append(query)
            }
        }
        return deduplicated
    }

    private static func applyCategoryFilter(_ items: [MKMapItem], spec: CategorySpec) -> [MKMapItem] {
        items.filter { item in
            if let category = item.pointOfInterestCategory, spec.excludedCategories.contains(category) {
                return false
            }

            guard !spec.excludedKeywords.isEmpty else { return true }
            let searchableText = normalized("\(item.name ?? "") \(item.placemark.title ?? "")")
            //Whole-word match: "bar" must not knock out "Barbecue" or "Rhubarb".
            return !spec.excludedKeywords.contains { keyword in
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: normalized(keyword)))\\b"
                return searchableText.range(of: pattern, options: .regularExpression) != nil
            }
        }
    }
        
    //What to search specifically for each one. Strict separation: a place belongs to exactly one category —
    //Food = meals, Cafes = coffee & pastry, Bars = cocktails/wine, Pubs = beer-first, Clubs = dance venues.
    private static func categorySpec(category: MapCategory) -> CategorySpec {
        let beautyExclusions: Set<MKPointOfInterestCategory> = [.beauty, .spa]
        let beautyKeywords = ["hairdresser", "hair salon", "barber", "coiffeur", "coiffeuse", "coiffure"]

        switch category {
        case .food:
            return .init(
                categories: [.restaurant, .foodMarket],
                queries: ["restaurant"],
                excludedCategories: [.cafe, .bakery, .brewery, .winery, .distillery, .nightlife],
                excludedKeywords: ["cafe", "café", "coffee", "pub", "tavern", "taverne", "microbrasserie", "nightclub"]
            )
        case .cafe:
            return .init(
                categories: [.cafe, .bakery],
                queries: ["coffee", "cafe"],
                excludedCategories: beautyExclusions,
                excludedKeywords: beautyKeywords
            )
        case .bar:
            return .init(
                categories: [.nightlife, .winery, .distillery],
                queries: ["cocktail bar", "bar"],
                unfilteredQueries: ["wine bar"],
                excludedCategories: beautyExclusions.union([.brewery]),
                excludedKeywords: beautyKeywords + ["pub", "tavern", "taverne", "microbrasserie", "brewery", "nightclub"]
            )
        case .pub:
            return .init(
                categories: [.brewery],
                unfilteredQueries: ["pub", "microbrasserie", "taproom"],
                excludedCategories: beautyExclusions,
                excludedKeywords: beautyKeywords + ["cocktail", "nightclub", "wine bar"]
            )
        case .club:
            return .init(
                unfilteredQueries: ["nightclub", "dance club"],
                excludedCategories: beautyExclusions.union([.brewery]),
                excludedKeywords: beautyKeywords + ["pub", "tavern", "taverne"]
            )
        case .park:
            return .init(
                categories: [.park, .nationalPark, .beach, .campground],
                queries: ["public park", "nature reserve", "trail"],
                excludedCategories: beautyExclusions.union([.parking, .carRental, .gasStation, .evCharger, .automotiveRepair]),
                excludedKeywords: beautyKeywords + [
                    "parking", "car park", "carpark", "park and ride", "park&ride", "parkade", "valet"
                ]
            )
        case .activity:
            return .init(
                categories: [.amusementPark, .fairground, .landmark, .movieTheater, .museum, .musicVenue,
                             .rockClimbing, .skating, .stadium, .bowling, .miniGolf, .zoo, .aquarium],
                queries: ["things to do"],
                excludedCategories: beautyExclusions,
                excludedKeywords: beautyKeywords
            )
        }
    }

    private struct CategorySpec {
        let categories: [MKPointOfInterestCategory]
        let queries: [String]
        let unfilteredQueries: [String]
        let excludedCategories: Set<MKPointOfInterestCategory>
        let excludedKeywords: [String]

        init(categories: [MKPointOfInterestCategory] = [],
             queries: [String] = [],
             unfilteredQueries: [String] = [],
             excludedCategories: Set<MKPointOfInterestCategory> = [],
             excludedKeywords: [String] = []) {
            self.categories = categories
            self.queries = queries
            self.unfilteredQueries = unfilteredQueries
            self.excludedCategories = excludedCategories
            self.excludedKeywords = excludedKeywords
        }
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
    
    func hasMovedSinceSearch() -> Bool {
        guard let lastCenter = lastSearchRegion?.center,
              let currentCenter = visibleRegion?.center else { return false }

        let last = CLLocation(latitude: lastCenter.latitude, longitude: lastCenter.longitude)
        let current = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
        //Past the flight's landing spot plus slack: even a short real pan flips the label, while the
        //flight itself (landing offset ≤ ~700 m at the 4500 m zoom clamp) stays under the slack and never can.
        return last.distance(from: current) > lastLandingDistance + Self.searchAreaSlack
    }
    
    func addSearchToDefaults(title: String, town: String) {
        defaults.updateRecentMapSearches(title: title, town: town)
        recentMapSearches = defaults.recentMapSearches.reversed() // So most recent appears at the top.
    }
    
    func deleteSearchFromDefaults(place: RecentPlace) {
        defaults.removeFromRecentMapSearches(place: place)
        recentMapSearches = defaults.recentMapSearches.reversed() // So most recent appears at the top
    }
}

