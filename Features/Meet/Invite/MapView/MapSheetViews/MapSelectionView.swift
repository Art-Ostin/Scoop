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
        
        VStack(alignment: .center, spacing: 14) {
            title
            locationActions
            locationLookAround
            
            addLocationButton
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .overlay(alignment: .topTrailing) {dismissButton}
        .padding(.vertical, 24)
        .padding(.horizontal)
        .ignoresSafeArea(.container, edges: .bottom)
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
            Text(pointOfInterestText())
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
                .font(.body(15, .medium))
                .frame(width: 35, height: 35)
                .glassIfAvailable(Circle())
                .contentShape(Circle())
                .foregroundStyle(Color.black)
        }
    }
    
    @ViewBuilder
    private var locationLookAround: some View {
        if let lookAroundScene {
            LookAroundPreview(initialScene: lookAroundScene)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if isLoadingLookAround {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private var locationActions: some View {
        let googleImage = Image("GoogleMapsIcon").scaleEffect(0.9)
        let safariImage = Image(systemName: "safari.fill").font(.body(14, .bold))
        let phoneImage = Image(systemName: "phone").font(.body(14, .bold))
        
        
        HStack(spacing: 16) {
            MapSelectionAction(text: "Maps", image: googleImage as! Image) { MapsRouter.openGoogleMaps(item: mapItem)}
            MapSelectionAction(text: "Website", image:  safariImage as! Image) { }
            MapSelectionAction(text: "Website", image:  phoneImage as! Image) { mapItem.phoneNumber ?? ""}
        }
    }
    
    private var test: some View {
        VStack(spacing: 5) {
            Image(systemName: "safari")
                .font(.body(14, .medium))
    
            Text("Website")
                .font(.body(14, .bold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 45)
        .foregroundStyle(Color.accent)
        .stroke(16, lineWidth: 1, color: .black)
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
    
    private func pointOfInterestText() -> String {
            mapItem.pointOfInterestCategory?
                .rawValue
                .replacingOccurrences(of: "MKPOICategory", with: "")
                .replacingOccurrences(
                    of: "([a-z])([A-Z])",
                    with: "$1 $2",
                    options: .regularExpression
                )
            ?? mapItem.placemark.title
            ?? ""
    }
}


private struct MapSelectionAction: View {
    let text: String
    let image: Image
    
    let onTap: () -> ()
    
    var body: some View {
        Button {
           onTap()
        } label: {
            HStack(spacing: 5) {
                image
                Text(text)
                    .font(.body(14, .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .foregroundStyle(Color.blue)
            .stroke(16, lineWidth: 1, color: .black)
        }
    }
}

