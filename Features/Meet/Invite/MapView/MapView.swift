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
    
    @Namespace private var ns

    
    
    var body: some View {
            Map(position: $vm.cameraPosition, selection: $vm.mapSelection) {
                UserAnnotation()
                ForEach(vm.results, id: \.self) {item in
                    let placemark = item.placemark
                    let isSelected = vm.mapSelection == item
                    let name = placemark.name ?? ""
                    let category = item.pointOfInterestCategory ?? .restaurant

                    Annotation(name, coordinate: placemark.coordinate,anchor: .bottom) {
                        if isSelected {
                            MapAnnotation(category: category)
                                .matchedGeometryEffect(id: "annotation", in: ns)
                        } else {
                            MapImageIcon(category: category)
                                .matchedGeometryEffect(id: "annotation", in: ns)
                        }
                    }
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
         .rockClimbing, .skating,
                 
        ]
    }

}
