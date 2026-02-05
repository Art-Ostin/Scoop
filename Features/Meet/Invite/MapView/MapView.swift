//
//  MapView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//

import SwiftUI
import MapKit


struct MapView: View {
    
    @State var vm = MapViewModel()
    @Environment(\.dismiss) var dismiss
    @Bindable var eventVM: TimeAndPlaceViewModel
    @FocusState var isFocused: Bool
    
    
    @State private var selectedDetent: PresentationDetent = .fraction(0.42)
    @State private var searchBarDetent: PresentationDetent = .fraction(0.1)
    @State private var searchBarRestaurant: PresentationDetent = .fraction(0.25)
    
    @State private var currentDetent: PresentationDetent = .fraction(0.1)
    @State private var selectionTask: Task<Void, Never>?
    
    var body: some View {
        Map(position: $vm.cameraPosition, selection: $vm.selection) {
            UserAnnotation()
            ForEach(vm.results, id: \.self) { item in
                    Marker(item: item)
                        .tag(MapSelection(item))
                        .tint(Color(red: 0.78, green: 0, blue: 0.35))
            }
        }
        .onMapCameraChange { context in
            vm.currentSpan = context.region.span
            vm.currentRegion = context.region
        }
        .mapStyle(.standard(pointsOfInterest: .including(pointsOfInterest)))
        .overlay(alignment: .topTrailing) { DismissButton() {dismiss()} }
        .onAppear {vm.locationManager.requestWhenInUseAuthorization() }
        .overlay(alignment: .top) { searchAreaButton }
        .sheet(isPresented: $vm.showSearch) {
            mapSearchView
        }
        .sheet(isPresented: $vm.showDetails, ) {
            if let mapItem = vm.selectedMapItem {
                mapItemInfoView(mapItem: mapItem)
            }
        }
        .onChange(of: vm.showDetails) { _, newValue in
            if newValue == false {
                vm.showSearch = true
                    currentDetent = .fraction(0.1)
            }
        }
        .onChange(of: vm.selection) { _, newSelection in
            Task { @MainActor in
                await vm.updateSelectedMapItem(from: newSelection)
                guard !Task.isCancelled else { return }
                vm.showDetails = vm.selectedMapItem != nil
                
                
                if let item = vm.selectedMapItem {
                    let coord = item.placemark.coordinate
                    let yOffset = vm.currentSpan.latitudeDelta * 0.15 //Gives slight offset
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.cameraPosition = .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: coord.latitude - yOffset,
                                                               longitude: coord.longitude),
                                span: vm.currentSpan
                            )
                        )
                    }
                }
            }
        }
    }
}

extension MapView {
    
    private var pointsOfInterest: [MKPointOfInterestCategory] {
        [.nightlife, .restaurant, .beach, .brewery, .cafe, .distillery,
         .foodMarket, .fairground, .landmark, .park, .musicVenue,
         .rockClimbing, .skating,
                 
        ]
    }
    
    private var searchAreaButton: some View {
        Button {
            Task { await vm.searchBarsInVisibleRegion() }
        } label: {
            Text("Search Area")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassIfAvailable(isClear: true, thinMaterial: true)
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
    }

    
    private var mapSearchView: some View {
        MapSearchView(vm: vm, currentDetent: $currentDetent)
            .presentationDetents([searchBarDetent,  .large])
            .presentationBackgroundInteraction(.enabled(upThrough: searchBarDetent))
    }

    
    
    private func mapItemInfoView(mapItem: MKMapItem) -> some View {
        
        return MapSelectionView(vm: vm, mapItem: mapItem) { mapItem in
            eventVM.event.location = EventLocation(mapItem: mapItem)
        }
        .presentationDetents([selectedDetent, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: selectedDetent))
        
    }
}


/*
 //Focuses the camera on the new position
  vm.cameraPosition = .region(
      MKCoordinateRegion(
          center: item.placemark.coordinate,
          span: vm.currentSpan
      )
  )

 */



//Come back to if I need to.
/*
 

 
 .animation(.easeInOut(duration: 0.3), value: vm.mapSelection)
 
 
 .overlay(alignment: .bottomTrailing) {
     MapUserLocationButton()
         .padding(.bottom, 150)
 }

 
 .onChange(of: vm.mapSelection) { oldValue, newValue in
     vm.showDetails = newValue != nil
 }
 */



private extension MKMapItem {
    var pointOfInterestTintColor: Color? {
        let kvcColorKeys = [
            "markerTintColor",
            "_markerTintColor",
            "pointOfInterestColor",
            "_pointOfInterestColor",
            "displayColor",
            "_displayColor"
        ]

        for key in kvcColorKeys {
            let selector = NSSelectorFromString(key)

            guard responds(to: selector) else {
                continue
            }

            if let uiColor = value(forKey: key) as? UIColor {
                return Color(uiColor: uiColor)
            }
        }

        return nil
    }
}
