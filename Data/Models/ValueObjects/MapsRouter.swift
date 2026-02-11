//
//  MapsRouter.swift
//  Scoop
//
//  Created by Art Ostin on 11/02/2026.
//



import MapKit
import UIKit

enum MapTarget {
    case googleOnly
    case appleOnly
    case googleThenApple
}

enum MapsRouter {
    static func open(item: MKMapItem, target: MapTarget = .googleThenApple) {
        switch target {
        case .googleOnly:
            _ = openGoogleMaps(item: item)
        case .appleOnly:
            openAppleMaps(item: item)
        case .googleThenApple:
            if !openGoogleMaps(item: item) {
                openAppleMaps(item: item)
            }
        }
    }

    @discardableResult
    
    static func openGoogleMaps(item: MKMapItem) -> Bool {
        guard let url = googleURL(for: item), UIApplication.shared.canOpenURL(url) else {
            return false
        }
        UIApplication.shared.open(url)
        return true
    }

    static func openAppleMaps(item: MKMapItem) {
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    private static func googleURL(for item: MKMapItem) -> URL? {
        let lat = item.placemark.coordinate.latitude
        let lon = item.placemark.coordinate.longitude
        let coords = "\(lat),\(lon)"
        return URL(string: "comgooglemaps://?q=\(coords)&center=\(coords)&zoom=15")
    }
}
