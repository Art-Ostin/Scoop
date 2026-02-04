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
        
    var body: some View {
            Map(position: $vm.cameraPosition, selection: $vm.selection) {
                UserAnnotation()
                
                ForEach(vm.results, id: \.self) { item in
                    Marker(item: item)
                        .tag(MapSelection(item))
                }
                
                
            }
            .onMapCameraChange { context in
                vm.currentSpan = context.region.span
            }
            .mapStyle(.standard(pointsOfInterest: .including(pointsOfInterest)))
            .overlay(alignment: .topTrailing) { DismissButton() {dismiss()} }
            .onAppear {vm.locationManager.requestWhenInUseAuthorization() }
            .overlay(alignment: .bottom) { GlassSearchBar(showSheet: $vm.showSearch, text: vm.searchText)}
            .sheet(item: $vm.selection) {
                mapItemInfoView(selection: selection)
            }
            .sheet(isPresented: $vm.showSearch) { MapSearchView(vm: vm) }
            .tint(Color.blue)
            .onChange(of: vm.selection) { _, newSelection in
                if let sel = newSelection,
                   let item = vm.results.first(where: { MapSelection($0) == sel }) {
                    vm.cameraPosition = .region(
                        MKCoordinateRegion(
                            center: item.placemark.coordinate,
                            span: vm.currentSpan
                        )
                    )
                    vm.showDetails = true
                } else {
                    vm.showDetails = false
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
    
    private func mapItemInfoView(selection:  MapSelection<MKMapItem>) -> some View {
        MapSelectionView(vm: vm, selection: selection) { mapItem in
            eventVM.event.location = EventLocation(mapItem: mapItem)
        }
        .presentationDetents([.height(360)])
        .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
        .presentationCornerRadius(16)
    }
}



//Come back to if I need to.
/*
 
 ForEach(vm.results, id: \.self) {item in
     let placemark = item.placemark
     let isSelected = vm.mapSelection == item
     let name = placemark.name ?? ""
     let category = item.pointOfInterestCategory ?? .restaurant

     Annotation(name, coordinate: placemark.coordinate,anchor: .bottom) {
         if isSelected {
             MapAnnotation(category: category)
         } else {
             MapImageIcon(category: category, isSearch: false)
         }
     }
 }
 
 
 .animation(.easeInOut(duration: 0.3), value: vm.mapSelection)
 
 
 .overlay(alignment: .bottomTrailing) {
     MapUserLocationButton()
         .padding(.bottom, 150)
 }

 
 .onChange(of: vm.mapSelection) { oldValue, newValue in
     vm.showDetails = newValue != nil
 }
 */

