//
//  CodableMK.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

//Created since MKMAPITEM does not conform to codable, thus have to create and extract a custom Location Model which does conform to codable, and thus can be used in the data

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
