//
//  MapsRouter.swift
//  Scoop
//
//  Created by Art Ostin on 11/02/2026.
//


/*
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
 */



import MapKit
import UIKit

enum MapTarget {
    case googleOnly
    case appleOnly
    case googleThenApple
}

enum MapsRouter {
    
    @discardableResult
    func openMaps(defaults: DefaultsManaging, item: MKMapItem? = nil, withDirections: Bool = false) -> Bool {
        if let preferredMapType = defaults.preferredMapType {
            if preferredMapType == .appleMaps {
                MapsRouter.openAppleMaps(item: item, withDirections: withDirections)
            } else if preferredMapType == .googleMaps {
                MapsRouter.openGoogleMaps(item: item, withDirections: withDirections)
            }
        } else {
            return false
        }
    }
    
    @discardableResult
    static func openGoogleMaps(item: MKMapItem? = nil, withDirections: Bool = false) -> Bool {
        if let item {
            guard let url = googleURL(for: item, withDirections: withDirections),
                  UIApplication.shared.canOpenURL(url) else {
                return false
            }
            UIApplication.shared.open(url)
            return true
        } else {
            if let appURL = URL(string: "comgooglemaps://"),
               UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
                return true
            } else if let webURL = URL(string: "https://maps.google.com/") {
                UIApplication.shared.open(webURL)
                return true
            }
        }
        return false
    }

    static func openAppleMaps(item: MKMapItem? = nil, withDirections: Bool = false) {
        if let item {
            if withDirections  {
                item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
            }
            let coordinate = item.placemark.coordinate
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

            item.openInMaps(launchOptions: [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
                MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: span)
            ])
        } else {
            if let appURL = URL(string: "maps://"), UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
            } else if let webURL = URL(string: "https://maps.apple.com/") {
                UIApplication.shared.open(webURL)
            }
        }
    }

    private static func googleURL(for item: MKMapItem, withDirections: Bool) -> URL? {
        let lat = item.placemark.coordinate.latitude
        let lon = item.placemark.coordinate.longitude
        let coords = "\(lat),\(lon)"
        let query = googleQuery(for: item, fallbackCoordinates: coords)

        guard var components = URLComponents(string: "comgooglemaps://") else {
            return nil
        }
        if withDirections {
            let destination = googleDirectionsDestination(for: item, fallbackCoordinates: coords)

            components.queryItems = [
                URLQueryItem(name: "daddr", value: destination),
                URLQueryItem(name: "directionsmode", value: "walking")
            ]
        } else {
            components.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "center", value: coords),
                URLQueryItem(name: "zoom", value: "15")
            ]
        }
        return components.url
    }
    
    private static func googleDirectionsDestination(for item: MKMapItem, fallbackCoordinates: String) -> String {
        let query = googleQuery(for: item, fallbackCoordinates: "")
        return query.isEmpty ? fallbackCoordinates : query
    }

    private static func googleQuery(for item: MKMapItem, fallbackCoordinates: String) -> String {
        let trimmedName = item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedAddress = item.placemark.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        var parts: [String] = []
        if !trimmedName.isEmpty {
            parts.append(trimmedName)
        }
        if !trimmedAddress.isEmpty && (trimmedName.isEmpty || !trimmedAddress.localizedCaseInsensitiveContains(trimmedName)) {
            parts.append(trimmedAddress)
        }
        
        let query = parts.joined(separator: ", ")
        return query.isEmpty ? fallbackCoordinates : query
    }
}
