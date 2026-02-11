//
//  MapAnnotationExample.swift
//  Scoop
//
//  Created by Art Ostin on 11/02/2026.
//

import SwiftUI


struct MapAnnotationExample: View {
    @State var showSheet = false
    var body: some View {
        Button("Show Actions") { showSheet = true }
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 24) {
                    Button("Google Maps") {
                        MapsRouter.openGoogleMaps(item: nil)
                    }
                    
                    MapDivider()
                    
                    Button("Apple Maps") {
                        MapsRouter.openAppleMaps(item: nil)
                    }
                }
                .font(.body(17, .bold)) // your default text
                .padding(20)
                .presentationDetents([.height(120)])
            }
    }
}
#Preview {
    MapAnnotationExample()
}
