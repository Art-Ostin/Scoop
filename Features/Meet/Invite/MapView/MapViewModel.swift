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
    var searchText: String = ""
    var results: [MKMapItem] = []
    var selection: MapSelection<MKMapItem>?
    var selectedMapItem: MKMapItem?
    
    var visibleRegion: MKCoordinateRegion?
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    private var categorySearchTask: Task<Void, Never>?
    
    var isLoadingCategory: Bool = false
    
    var markerTint: Color {
        selectedMapCategory?.mainColor ?? Color.appColorTint
    }
    
    var selectedMapCategory: MapCategory? {
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
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = searchText
        let res = try? await MKLocalSearch(request: req).start()
        results = res?.mapItems ?? []
    }
    
    private func onCategorySelect() {
        categorySearchTask?.cancel()
        
        if let category = selectedMapCategory {
            isLoadingCategory = true
            categorySearchTask = Task { [weak self] in
                await self?.searchCategory(category: category)
                self?.searchText = category.description
            }
        } else {
            //If set to nil remove all the values
            isLoadingCategory = false
            if results.count > 2 { //I.e. Only remove if a category is selected -> I.e. many
                withAnimation(.easeInOut(duration: 0.3)) {
                    results.removeAll()
                    searchText = ""
                }
            }
        }
    }
    
    //Search and assign all the categories
    private func searchCategory(category: MapCategory) async {
            defer {
                if !Task.isCancelled { isLoadingCategory = false }
            }
            guard let region = visibleRegion else { return }
            let spec = Self.categorySpec(category: category) //Get the specifics to search
            let plans = [SearchPlan(query: nil, categories: spec.categories)] +
            spec.queries.map { SearchPlan(query: $0, categories: spec.categories) } +
            spec.queries.prefix(2).map { SearchPlan(query: $0, categories: nil) }
            let foundItems = await Self.search(region: region, plans: plans)
            guard !Task.isCancelled else { return }
            results = foundItems
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
        
    //What to search specifically for Each one
    private static func categorySpec(category: MapCategory) -> (categories: [MKPointOfInterestCategory], queries: [String]) {
        switch category {
        case .food:
            return ([.restaurant, .foodMarket, .cafe], ["restaurant", "food", "dining", "eat"])
        case .cafe:
            return ([.cafe], ["cafe", "coffee", "espresso", "tea"])
        case .bar:
            return ([.nightlife, .distillery, .winery], ["bar", "cocktail", "drinks", "lounge"])
        case .pub:
            return ( [.brewery], [ "pub", "Microbrasserie", "tavern", "alehouse", "beer"])
        case .club:
            return ([.nightlife, .musicVenue], ["nightclub", "dance", "dj", "music"])
        case .park:
            return ([.park, .nationalPark, .beach, .campground], ["park", "outdoors", "nature", "trail"])
        case .activity:
            return (
                [.amusementPark, .fairground, .landmark, .movieTheater, .museum, .musicVenue, .rockClimbing, .skating, .stadium],
                ["activity", "things to do", "fun", "attractions"]
            )
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
    
}



/*
 
 private static func scaledRegion(_ region: MKCoordinateRegion, by scale: CLLocationDegrees) -> MKCoordinateRegion {
     MKCoordinateRegion(
         center: region.center,
         span: MKCoordinateSpan(
             latitudeDelta: min(region.span.latitudeDelta * scale, 180),
             longitudeDelta: min(region.span.longitudeDelta * scale, 360)
         )
     )
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

 private static func normalizedLongitude(_ longitude: CLLocationDegrees) -> CLLocationDegrees {
     var value = longitude.truncatingRemainder(dividingBy: 360)
     if value > 180 { value -= 360 }
     if value < -180 { value += 360 }
     return value
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

 */
