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
            }
            .mapStyle(.standard(pointsOfInterest: .including(pointsOfInterest)))
            .overlay(alignment: .topTrailing) { DismissButton() {dismiss()} }
            .onAppear {vm.locationManager.requestWhenInUseAuthorization() }
            .overlay(alignment: .bottom) { GlassSearchBar(showSheet: $vm.showSearch, text: vm.searchText)}
            .sheet(isPresented: $vm.showDetails, ) {
                if let mapItem = vm.selectedMapItem {
                    mapItemInfoView(mapItem: mapItem)
                }
            }
            .sheet(isPresented: $vm.showSearch) { MapSearchView(vm: vm) }
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
