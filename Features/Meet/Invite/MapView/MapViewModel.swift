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
    
    var results = [MKMapItem]()
    
    var showDetails: Bool = false
    var showSearch: Bool = false 
    
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

        guard let feature = selection.feature else { selectedMapItem = nil; print("Hello World") ; return }


        
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
}



//Come back to If I need to
/*
 
 var mapSelection: MKMapItem? {
     didSet {
         guard let item = mapSelection else { return }
         cameraPosition = .region(
             MKCoordinateRegion(
                 center: item.placemark.coordinate,
                 span: currentSpan
             )
         )
     }
 }


 
 */
