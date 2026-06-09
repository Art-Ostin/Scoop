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
    var category: String?

    init(mapItem: MKMapItem) {
        name = mapItem.name
        latitude = mapItem.placemark.coordinate.latitude
        longitude = mapItem.placemark.coordinate.longitude
        address = mapItem.placemark.title
        category = mapItem.pointOfInterestCategory?.rawValue
    }

    var mapItem: MKMapItem {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        item.pointOfInterestCategory = category.map { MKPointOfInterestCategory(rawValue: $0) }
        return item
    }
}
