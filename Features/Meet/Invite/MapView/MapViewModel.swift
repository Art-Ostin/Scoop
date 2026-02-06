//
//  MapViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//

import Foundation
import SwiftUI
import MapKit
//
//enum MapSheetType: String, Identifiable {
//    case search
//    case info
//
//    var id: String { rawValue }
//}



@Observable class MapViewModel {
    
    
    //The Object to Track the User's Location
    let locationManager = CLLocationManager()
    
    //The Inputted Text by the User
    var searchText: String = ""

    var results = [MKMapItem]()
    
    var lookAroundScene: MKLookAroundScene?
    
    var selection: MapSelection<MKMapItem>?
    
    var selectedMapItem: MKMapItem? {
        didSet {
            updateMapRegion(mapItem: selectedMapItem)
        }
    }
    
    @MainActor
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
        let results = try? await MKLocalSearch(request: request).start()
        await MainActor.run {
            self.results = results?.mapItems ?? []
        }
    }
        
    func searchBarsInVisibleRegion() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "bar"
        request.region = currentRegion
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.nightlife])
        do {
            let response = try await MKLocalSearch(request: request).start()
            await MainActor.run {
                self.results = response.mapItems
            }
        } catch {
            print(error)
        }
    }
    
    var mapRegion: MapCameraPosition = .userLocation(fallback: .automatic)
        
    var currentSpan: MKCoordinateSpan = .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
    
    var currentRegion: MKCoordinateRegion = .init()
    
    func updateMapRegion(mapItem: MKMapItem?) {
        //get the coordinate of new Item and
        guard let item = mapItem else { return }
        let coordinate = item.placemark.coordinate
        let yOffset = currentSpan.latitudeDelta * 0.15
        
        withAnimation(.easeInOut) {
            currentRegion = MKCoordinateRegion (
                center: CLLocationCoordinate2D(latitude: coordinate.latitude - yOffset,
                                               longitude: coordinate.longitude),
                span: currentSpan
            )
        }
    }
}





/*
 if let item = vm.selectedMapItem {
     let coord = item.placemark.coordinate
     let yOffset = vm.currentSpan.latitudeDelta * 0.15
     withAnimation(.easeInOut(duration: 0.3)) {
         vm.mapRegion = .region(
             MKCoordinateRegion(
                 center: CLLocationCoordinate2D(latitude: coord.latitude - yOffset,
                                                longitude: coord.longitude),
                 span: vm.currentSpan
             )
         )
     }
 }

 */
