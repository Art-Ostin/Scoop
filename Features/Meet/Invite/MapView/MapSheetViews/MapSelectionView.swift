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
    let mapItem: MKMapItem
    let onExitSelection: (MapSheets) -> Void
    let selectedLocation: (MKMapItem) -> Void
    @Environment(\.openURL) private var openURL
    
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoadingLookAround = false
    
    @State private var noPreview = false
    
    var body: some View {
        
        //Have overlay topLeft scoop Logo when done
        VStack(alignment: .center, spacing: 16) {
            VStack(spacing: 8) {
                title
                locationActions
                    .padding(.horizontal, 4)
            }
            locationLookAround
            addLocationButton
            
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .overlay(alignment: .topTrailing) {dismissButton}
        .overlay(alignment: .topLeading) { searchButton}
        .padding(.vertical, 16)
        .padding(.horizontal)
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.easeInOut(duration: 0.3), value: vm.showAnimation ?  isLoadingLookAround : nil)
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
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(pointOfInterestText())
                .font(.footnote)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 36)
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
    
    private var searchButton: some View {
        Button {
            onExitSelection(.large)
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.body(17, .bold))
                .frame(width: 35, height: 35, alignment: .center)
                .offset(y: -4)
                .contentShape(Circle())
                .foregroundStyle(Color.black)
        }
    }
    
    @ViewBuilder
    private var locationLookAround: some View {
        if let lookAroundScene {
            LookAroundPreview(initialScene: lookAroundScene)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        } else if isLoadingLookAround {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))
        } else {
            ClearRectangle(size: 60)
        }
    }
    
    @ViewBuilder
    private var locationActions: some View {
        
        HStack(spacing: 16) {
            MapSelectionAction(text: "Reviews") {
                 MapsRouter.openGoogleMaps(item: mapItem)
             } icon: {
                 Image("GoogleMapsIcon")
                     .scaleEffect(0.9)
             }
             
             MapSelectionAction(text: "Website", isEnabled: websiteURL != nil) {
                 openWebsite()
             } icon: {
                 Image(systemName: "safari.fill")
                     .font(.body(14, .bold))
             }
             
             MapSelectionAction(text: "Call", isEnabled: phoneURL != nil) {
                 callLocation()
             } icon: {
                 Image(systemName: "phone.fill")
                     .font(.body(14, .bold))
             }
            
        }
    }
    
    private var websiteURL: URL? {
        mapItem.url
    }
    
    private var phoneURL: URL? {
        guard let phoneNumber = mapItem.phoneNumber else { return nil }
        let sanitized = phoneNumber.filter { $0.isNumber || $0 == "+" }
        guard !sanitized.isEmpty else { return nil }
        return URL(string: "tel://\(sanitized)")
    }
    
    private func openWebsite() {
        guard let website = mapItem.url else { return }
        openURL(website)
    }
    
    private func callLocation() {
         guard let phoneURL else { return }
         openURL(phoneURL)
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
    
    private var dismissButton: some View {
        Button {
            onExitSelection(.optionsAndSearchBar)
            //Only remove text if it is not a category (i.e. if more than 3 selected)
            if !(vm.results.count > 3) {
                vm.searchText = ""
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
    
}


private struct MapSelectionAction<Icon: View>: View {
    let text: String

    var isEnabled = true
    let onTap: () -> Void
    @ViewBuilder let icon: () -> Icon

    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                icon()
                Text(text)
                    .font(.body(14, .bold))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 35)
        .foregroundStyle(isEnabled ? Color(red: 0, green: 0.09, blue: 0.72) : Color.gray)
        .stroke(24, lineWidth: 1.2, color: isEnabled ?  Color(red: 0.82, green: 0.82, blue: 0.82) : Color(red: 0.92, green: 0.92, blue: 0.92) )
        .disabled(!isEnabled)
    }
}
