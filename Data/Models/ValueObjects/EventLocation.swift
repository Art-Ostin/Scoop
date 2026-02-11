//
//  EventLocation.swift
//  Scoop
//
//  Created by Art Ostin on 31/01/2026.
//

import MapKit
import UIKit


struct EventLocation: Equatable, Codable {
    var name: String?
    var latitude: Double
    var longitude: Double
    var address: String?

    init(mapItem: MKMapItem) {
        name = mapItem.name
        latitude = mapItem.placemark.coordinate.latitude
        longitude = mapItem.placemark.coordinate.longitude
        address = mapItem.placemark.title
    }
    
    var mapItem: MKMapItem {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        return item
    }
}

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



@MainActor
func OpenGoogleMaps(location: String? = nil) {
    let q = location?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    let urlString = q.map { "comgooglemaps://?q=\($0)" } ?? "comgooglemaps://"
    guard let url = URL(string: urlString) else { return }
    UIApplication.shared.open(url)
}


/* Need to also install PList for this. 
 import UIKit
 import CoreLocation

 func openMaps(to coordinate: CLLocationCoordinate2D, placeName: String? = nil) {
     let lat = coordinate.latitude
     let lon = coordinate.longitude

     // Prefer Google Maps app if it’s installed
     if let googleURL = URL(string: "comgooglemaps://?q=\(lat),\(lon)&center=\(lat),\(lon)&zoom=14"),
        UIApplication.shared.canOpenURL(googleURL) {
         UIApplication.shared.open(googleURL)
         return
     }

     // Otherwise fall back to Apple Maps
     let name = (placeName ?? "Destination")
         .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Destination"
     let appleURL = URL(string: "http://maps.apple.com/?ll=\(lat),\(lon)&q=\(name)")!
     UIApplication.shared.open(appleURL)
 }

 */
