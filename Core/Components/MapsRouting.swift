//
//  MapsRouting.swift
//  Scoop
//
//  Created by Art Ostin on 22/01/2026.
//

import MapKit

enum MapsRouting {
    
    @MainActor
    static func openMaps(place: EventLocation) async {
        let coord = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        let name = place.name ?? "Meet Location"
        let address = place.address ?? ""
        
        let fallback = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        fallback.name = name
        
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = [name, address].filter { !$0.isEmpty }.joined(separator: " ")
            request.region = MKCoordinateRegion(center: coord, latitudinalMeters: 1500, longitudinalMeters: 1500)
            
            let response = try await MKLocalSearch(request: request).start()
            (response.mapItems.first ?? fallback).openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
            ])
        } catch {
            fallback.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
            ])
        }
    }
}
