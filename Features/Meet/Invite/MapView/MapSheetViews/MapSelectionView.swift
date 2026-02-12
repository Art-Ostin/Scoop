//
//  MapSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI
import MapKit


struct MapSelectionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: MapViewModel
    
    let mapItem: MKMapItem
    
    @Binding var showMapAction: Bool
    
    let selectedLocation: (MKMapItem) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mapItem.name ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                        Text(mapItem.placemark.title ?? "")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    
                    Button {
                        MapsRouter.openGoogleMaps(item: mapItem)                        
                    } label: {
                        Text("Google Maps Directions")
                    }

                    
                    
                    
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            vm.selection = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.gray, Color(.systemGray6))
                    }
                }
                
                Button {
                    selectedLocation(mapItem)
                    dismiss()
                } label:   {
                    Text("Add Location")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accent)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .padding(24)
            
        }
    }
}
