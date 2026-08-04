//
//  MapSelectionView.swift
//  Scoop
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
    @State private var loadedSceneID: String?
    
    @State private var writeMaps = false
        
    var body: some View {
        
        VStack(alignment: .center, spacing: Spacing.md) {
            VStack(spacing: Spacing.xs) {
                title
                locationActions
                    .padding(.horizontal, Spacing.xxs)
            }
            locationLookAround
            addLocationButton
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .overlay(alignment: .topTrailing) {dismissButton}
        .overlay(alignment: .topLeading) { searchButton}
        .padding(.vertical, Spacing.md)
        .padding(.horizontal)
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.transition, value: vm.showAnimation ?  isLoadingLookAround : nil) //Fixes Bug -> fades in when transition but not when first selected
        .task(id: lookAroundRequestID) {
            await loadLookAroundScene()
        }
        .onAppear {
            writeMaps = mapItem.pointOfInterestCategory == nil
        }
    }
}

extension MapSelectionView {
    
    private var title: some View {
        VStack(alignment: .center, spacing: Spacing.xxs) {
            Text(mapItem.name ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(pointOfInterestText())
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.xl)
    }
    
    private var addLocationButton: some View {
        Text("Add Location")
            .font(.body(18, .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.textAccent, in: .rect(cornerRadius: CornerRadius.xl))
            .shrinkPress {
                selectedLocation(mapItem)
            }
    }
    
    private var searchButton: some View {
        Button {
            onExitSelection(.large)
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.body(17, .bold))
                .frame(width: 35, height: 35, alignment: .center)
                .contentShape(Circle())
                .foregroundStyle(Color.textPrimary)
        }
    }
    
    @ViewBuilder
    private var locationLookAround: some View {
        if let lookAroundScene {
            LookAroundPreview(initialScene: lookAroundScene)
                .frame(maxHeight: .infinity)
                .clipShape(.rect(cornerRadius: CornerRadius.xl))
        } else if isLoadingLookAround {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: CornerRadius.xl))
        } else {
            Color.clear
                .frame(width: 140) //Replace with cool design when made
                .frame(maxHeight: .infinity)
                .overlay(alignment: .center) {
                    Text("No Preview Available")
                        .font(.body(13, .bold))
                        .foregroundStyle(Color.textPrimary)
                }
        }
    }
    
    @ViewBuilder
    private var locationActions: some View {
        
        HStack(spacing: Spacing.md) {
            MapSelectionAction(text: writeMaps ? "Maps" : "Reviews", tint: .actionBlue) {
                 MapsRouter.openGoogleMaps(item: mapItem)
             } icon: {
                 Image("GoogleMapsIcon")
                     .scaleEffect(0.9)
             }
             
             MapSelectionAction(text: "Website", isEnabled: websiteURL != nil) {
                 openWebsite()
             } icon: {
                 Image("InternetSymbol")
                     .font(.body(14, .bold))
             }
             
             MapSelectionAction(text: "Call", isEnabled: phoneURL != nil) {
                 callLocation()
             } icon: {
                 Text("📞")
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

    //Returning from the full-screen Look Around re-runs this task; re-fetching there would
    //tear down the preview the system is still flying back into, so the same place is a no-op.
    @MainActor
    private func loadLookAroundScene() async {
        let requestID = lookAroundRequestID
        guard loadedSceneID != requestID else { return }

        lookAroundScene = nil
        isLoadingLookAround = true
        defer { isLoadingLookAround = false }

        do {
            lookAroundScene = try await MKLookAroundSceneRequest(mapItem: mapItem).scene
            loadedSceneID = requestID //Only on success, so a failed load still retries
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
        Image(systemName: "xmark")
            .font(.body(17, .bold))
            .frame(width: 35, height: 35, alignment: .center)
            .contentShape(Circle())
            .foregroundStyle(Color.textPrimary)
            .shrinkPress {
                onExitSelection(.optionsAndSearchBar)
            }
    }
}


private struct MapSelectionAction<Icon: View>: View {
    //Injected
    let text: String
    var tint: Color = .blackFill
    var isEnabled = true
    let onTap: () -> Void
    @ViewBuilder let icon: () -> Icon


    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                icon()
                Text(text)
                    .font(.body(14, .bold))
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 35)
        .foregroundStyle(isEnabled ? tint : Color.textPlaceholder)
        .background(Color(red: 0.96, green: 0.97, blue: 0.97), in: .capsule)
        .disabled(!isEnabled)
    }
}

