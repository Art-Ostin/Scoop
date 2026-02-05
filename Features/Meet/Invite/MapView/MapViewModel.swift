//
//  MapViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//

import Foundation
import SwiftUI
import MapKit

@Observable class MapViewModel {
    
    //Setting Starting Position of CameraView
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
        
    //The Object to Track the User's Location
    let locationManager = CLLocationManager()
    
    //The Inputted Text by the User
    var searchText: String = ""
    
    var showInfo: Bool = false
    var showSearch: Bool = true
    
    var results = [MKMapItem]()
    
    var lookAroundScene: MKLookAroundScene?
    
    var selection: MapSelection<MKMapItem>?
    var selectedMapItem: MKMapItem?
    
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
            
    var currentSpan: MKCoordinateSpan = .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
    
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let results = try? await MKLocalSearch(request: request).start()
        await MainActor.run {
            self.results = results?.mapItems ?? []
        }
    }
    
    var currentRegion: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
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
            print("Search bars error:", error)
        }
    }
}

/*
 var showDetails: Bool = false
 var showSearch: Bool = true

 */
