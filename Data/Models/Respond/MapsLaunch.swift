//
//  MapsLaunch.swift
//  Scoop
//
//  Created by Art Ostin on 03/05/2026.
//

import MapKit

struct MapsLaunchRequest: Identifiable {
    let id = UUID()
    let item: MKMapItem?
    let withDirections: Bool
}
