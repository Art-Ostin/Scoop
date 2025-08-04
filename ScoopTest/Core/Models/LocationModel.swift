//
//  CodableMK.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import Foundation
import MapKit

struct EventLocation: Codable {
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

struct ProfileID: Codable {
    var email: String?
    var id: String?
}
