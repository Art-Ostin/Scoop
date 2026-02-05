//
//  MapView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//

import SwiftUI
import MapKit

enum SheetState: Equatable {
    case searchCollapsed
    case searchExpanded
    case selection
}


struct MapView: View {
    
    @State var vm = MapViewModel()
    @Environment(\.dismiss) var dismiss
    @Bindable var eventVM: TimeAndPlaceViewModel
    @FocusState var isFocused: Bool
    

    @State private var currentDetent: PresentationDetent = .fraction(0.1)
    private let searchBarDetent: PresentationDetent = .fraction(0.1)
    private let selectedDetent: PresentationDetent = .fraction(0.42)

        
    @State private var selectionTask: Task<Void, Never>?
    
    @State var showSheet: Bool = true
    
    var body: some View {
        Map(position: $vm.cameraPosition, selection: $vm.selection) {
            UserAnnotation()
            ForEach(vm.results, id: \.self) { item in
                    Marker(item: item)
                        .tag(MapSelection(item))
                        .tint(Color(red: 0.78, green: 0, blue: 0.35))
            }
        }
        .onMapCameraChange {context in
            vm.currentSpan = context.region.span
            vm.currentRegion = context.region
        }
        .mapStyle(.standard(pointsOfInterest: .including(pointsOfInterest)))
        .overlay(alignment: .topTrailing) { DismissButton() {dismiss()} }
        .onAppear {vm.locationManager.requestWhenInUseAuthorization() }
        .overlay(alignment: .top) { searchAreaButton }
        .onChange(of: vm.selection) { _, newSelection in itemSelected(newSelection) }
        .sheet(isPresented: .constant(true)) {searchView}
        .sheet(isPresented: $vm.showInfo) {infoView }
        .onChange(of: vm.showInfo) {
            if vm.showInfo == false {
                currentDetent = .fraction(0.1)
//                vm.showSearch = true
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
    
    private var searchView: some View {
        MapSearchView(vm: vm, currentDetent: $currentDetent)
            .presentationDetents([searchBarDetent,  .large], selection: $currentDetent)
            .presentationBackgroundInteraction(.enabled(upThrough: searchBarDetent))
            .interactiveDismissDisabled(true)
    }
    
    @ViewBuilder
    private var infoView: some View {
        if let mapItem = vm.selectedMapItem {
            MapSelectionView(vm: vm, mapItem: mapItem) { mapItem in
                eventVM.event.location = EventLocation(mapItem: mapItem)
            }
            .presentationDetents([selectedDetent])
            .presentationBackgroundInteraction(.enabled(upThrough: selectedDetent))
        }
    }
    
    private func itemSelected(_ newSelection: MapSelection<MKMapItem>?)  {
        Task { @MainActor in
            //1. Load selected Item into the selectedMap Item as a MKMapItem
            await vm.updateSelectedMapItem(from: newSelection)
            guard !Task.isCancelled else { return }
            
            //2. Toggle the UI to show Info and hide search
            if vm.selectedMapItem != nil {
//               vm.showSearch = false
                vm.showInfo = true
            } else {
                vm.showSearch = true
            }
            
            //3. Update camera position to new centre (the actual selection dealt with through map)
            if let item = vm.selectedMapItem {
                let coord = item.placemark.coordinate
                let yOffset = vm.currentSpan.latitudeDelta * 0.15
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




/*
 .interactiveDismissDisabled(sheetState != .selection)
 */




/*
 .onChange(of: vm.showDetails) {_, newValue in
     if newValue == false {
         vm.showSearch = true
             currentDetent = .fraction(0.1)
     }
 }

 
 .sheet(isPresented: $vm.showDetails) {
     if let mapItem = vm.selectedMapItem {
         mapItemInfoView(mapItem: mapItem)
     }
 }
 
 
 .sheet(isPresented: $vm.showSearch) { mapSearchView}


 .sheet(isPresented: $showSheet) {
     sheetContent
         .interactiveDismissDisabled(sheetState != .selection)
         .presentationDetents(detentsForState, selection: $currentDetent)
         .presentationBackgroundInteraction(.enabled(upThrough: upThroughDetent))
         .onChange(of: currentDetent) { _, newDetent in
             guard sheetState != .selection else { return }
             sheetState = (newDetent == searchBarDetent) ? .searchCollapsed : .searchExpanded
         }
 }

 
 
 */
