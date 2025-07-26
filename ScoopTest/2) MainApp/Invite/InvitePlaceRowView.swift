//
//  InvitePlaceView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI
import MapKit

struct InvitePlaceRowView: View {
    
    @Binding var showMapView: Bool
    
    
    @Binding var selectedPlace: MKMapItem?
    
    var body: some View {
            
            if selectedPlace == nil {
                HStack {
                    Text("Place")
                        .font(.body(20, .bold))
                    Spacer()
                    
                    Image("InvitePlace")
                        .onTapGesture {
                            showMapView.toggle()
                        }
                }
            } else {
                HStack {
                    VStack {
                        Text(selectedPlace?.name ?? "")
                            .font(.body(18))
                        Text(selectedPlace?.placemark.title ?? "")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Image("EditButton")
                }
            }
            
            
            
        }
    }

#Preview {
    InvitePlaceRowView(showMapView: .constant(false), selectedPlace: .constant(nil))
}
