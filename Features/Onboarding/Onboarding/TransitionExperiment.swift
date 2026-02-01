//
//  TransitionExperiment.swift
//  Scoop
//
//  Created by Art Ostin on 20/01/2026.
//

import SwiftUI
import MapKit

struct MapExperiment: View {
    
    let coordinate = CLLocationCoordinate2D(latitude: 45.5019, longitude: -73.5674) // Montreal

    
    var body: some View {
        Button("Open Maps"){
            let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            destination.name = "Meet location"

            destination.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }
    
}

#Preview {
    MapExperiment()
}

