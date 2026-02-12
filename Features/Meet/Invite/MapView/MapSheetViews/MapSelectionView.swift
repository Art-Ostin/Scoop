//
//  MapSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI
import MapKit


struct MapSelectionView: View {
    
    
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    let mapItem: MKMapItem
    let selectedLocation: (MKMapItem) -> Void
    
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoadingLookAround = false
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            title
            locationLookAround
            addLocationButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {dismissButton}
        .padding(24)
    }
}

extension MapSelectionView {
    
    private var title: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mapItem.name ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            Text(mapItem.placemark.title ?? "")
                .font(.footnote)
                .foregroundStyle(.gray)
        }
    }
    
    private var addLocationButton: some View {
        Button {
            selectedLocation(mapItem)
        } label: {
            Text("Add Location")
                .font(.body(18, .bold))
                .foregroundStyle(.white)
                .frame(width: 250)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.accent)
                )
        }
    }
    
    private var dismissButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                sheet = .optionsAndSearchBar
                vm.selection = nil
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(.gray, Color(.systemGray6))
        }
    }
    
    @ViewBuilder
    private var locationLookAround: some View {
        if let lookAroundScene {
            LookAroundPreview(initialScene: lookAroundScene)
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if isLoadingLookAround {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}


/*
 
 
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
             
             
             
             
         }
         
     }
     .scrollIndicators(.hidden)
     .padding(24)

 */




/*
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

 */
