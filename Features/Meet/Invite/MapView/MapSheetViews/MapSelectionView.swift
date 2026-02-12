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
    @Environment(\.openURL) private var openURL
    
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoadingLookAround = false
    var body: some View {
        
        //HAve overlay topLeft scoop Logo when done
        VStack(alignment: .center, spacing: 12) {
            VStack(spacing: 8) {
                title
                locationActions
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
        .animation(.easeInOut(duration: 0.3), value: isLoadingLookAround)
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
            Image(systemName: "magnifyingglass")
                .font(.body(17, .bold))
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
    
    private var searchButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                vm.selection = nil
                sheet = .large
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
            HStack(spacing: 6) {
                icon()
                Text(text)
                    .font(.body(14, .bold))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 35)
        .foregroundStyle(isEnabled ? Color.blue : Color.gray)
        .stroke(16, lineWidth: 1, color: .black)
        .disabled(!isEnabled)
    }
}

