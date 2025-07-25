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
    
    var lookAroundScene: MKLookAroundScene? 
    
    var mapSelection: MKMapItem? {
        didSet {
            cameraPosition = mapSelection.map { item in
                .region(MKCoordinateRegion(center: item.placemark.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            } ?? .userLocation(fallback: .automatic)
        }
    }
    
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let results = try? await MKLocalSearch(request: request).start()
        self.results = results?.mapItems ?? []
    }
}
