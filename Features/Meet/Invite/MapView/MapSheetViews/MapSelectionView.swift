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
        .task(id: lookAroundRequestID) {
            await loadLookAroundScene()
        }
    }
}

extension MapSelectionView {
    
    private var title: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(mapItem.name ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            Text(mapItem.pointOfInterestCategory?.rawValue ?? mapItem.placemark.title ?? "")
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
            Image(systemName: "xmark")
                .font(.body(18, .bold))
                .frame(width: 45, height: 45)
                .glassIfAvailable(Circle())
                .contentShape(Circle())
                .foregroundStyle(Color.black)
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
    
    private var locationActions: some View {
        HStack(spacing: 16) {
            test
            test
            test
        }
    }
    
    private var test: some View {
        VStack {
            Image(systemName: "safari")
            Text("Website")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 55)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color.accent.opacity(0.3))
        )
        
    }
    
    private var lookAroundRequestID: String {
        let coordinate = mapItem.placemark.coordinate
        return "\(mapItem.name ?? "")-\(coordinate.latitude)-\(coordinate.longitude)"
    }

    @MainActor
    private func loadLookAroundScene() async {
        lookAroundScene = nil
        isLoadingLookAround = true
        defer { isLoadingLookAround = false }
        
        do {
            lookAroundScene = try await MKLookAroundSceneRequest(mapItem: mapItem).scene
        } catch {
            lookAroundScene = nil
        }
    }
}

