//
//  Simpleap.swift
//  Scoop
//
//  Created by Art Ostin on 04/02/2026.
//
import SwiftUI
import MapKit

struct SimplePOIMapView: View {

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.10)
        )
    )

    // This is the key: selecting Apple-rendered map features (POIs, etc.)
    @State private var selection: MapFeature?
    
    
    var body: some View {
        Map(position: $position, selection: $selection)
            .ignoresSafeArea()
            .onChange(of: selection) { feature in
                guard let feature else { return }

                // If you only care about POIs, keep this filter:
                guard feature.pointOfInterestCategory != nil else { return }

                print(feature.title ?? "<No title>")
            }
    }
}

#Preview { SimplePOIMapView() }
