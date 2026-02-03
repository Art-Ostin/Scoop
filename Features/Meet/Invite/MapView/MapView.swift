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
    @Binding var vm2: TimeAndPlaceViewModel
    @State var selectedPlace: MKMapItem?
    @FocusState var isFocused: Bool
    @State private var searchBarFrame: CGRect = .zero
    @State private var searchIconFrame: CGRect = .zero

    
    
    var body: some View {
//        NavigationStack {
            Map(position: $vm.cameraPosition, selection: $vm.mapSelection) {
                UserAnnotation()
                
                ForEach(vm.results, id: \.self) { item in
                    let placemark = item.placemark
                    Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                        .tag(item)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .including(pointsOfInterest)))
            .overlay(alignment: .bottomTrailing) {
                MapUserLocationButton()
                    .padding(.bottom, 150)
            }
            .overlay(alignment: .topTrailing) { DismissButton() {dismiss()} }
            .onAppear { vm.locationManager.requestWhenInUseAuthorization() }
            .overlay(alignment: .bottom) {
                GlassSearchBar(showSheet: $vm.showSearch)

//                GlassSearchBar(showSheet: $vm.showSearch)
            }
            .onChange(of: vm.mapSelection) { oldValue, newValue in
                vm.showDetails = newValue != nil
            }
            .sheet(isPresented: $vm.showDetails, content: {
                MapSelectionView(vm: $vm, selectedPlace: $selectedPlace, vm2: $vm2, onCloseMap: {
                    dismiss()
                })
                .presentationDetents([.height(340)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                .presentationCornerRadius(16)
            })
            .sheet(isPresented: $vm.showSearch) {
                MapSearchView(vm: vm)
            }
            .tint(Color.blue)
        }
    }

extension MapView {
    

    private var pointsOfInterest: [MKPointOfInterestCategory] {
        [.nightlife, .restaurant, .beach, .brewery, .cafe, .distillery,
         .foodMarket, .fairground, .landmark, .park, .musicVenue,
         .rockClimbing, .skating]
    }

}

/*
 private var declineButton: some View {
     Button {
         dismiss()
     } label: {
         Image(systemName: "xmark")
             .font(.body(18, .bold))
             .padding(12)
             .glassIfAvailable(Circle())
             .contentShape(Circle())
             .foregroundStyle(Color.black)
             .padding(.horizontal)
     }
 }
 
 */




//Need Later on
/*
 .overlay(alignment: .top) {
     MapSearchView(vm: vm)
 }

 .mapControls {
     MapUserLocationButton()
 }
 */

/*
 MapSearchView(vm: vm)

 */



/*
 //
 //
 //
 //            .overlay(alignment: .bottom) {
 //                GlassSearchBar(text: $vm.searchText, showSheet: $vm.showSearch)
 //            }

 */
