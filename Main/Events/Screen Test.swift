//
//  Screen Test.swift
//  Scoop
//
//  Created by Art Ostin on 21/01/2026.
//

import SwiftUI
import MapKit

struct MiniMap: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(initialPosition: .camera(.init(centerCoordinate: coordinate, distance: 800))) {
            Marker("", coordinate: coordinate)
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal)
    }
}

#Preview {
    MiniMap(coordinate: .init(latitude: 45.5088, longitude: -73.5618))
}
