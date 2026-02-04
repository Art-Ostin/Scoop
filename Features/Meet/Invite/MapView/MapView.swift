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
            Map(position: $vm.cameraPosition, selection: $vm.mapSelection) {
                UserAnnotation()
                ForEach(vm.results, id: \.self) { item in
                    let category = item.pointOfInterestCategory
                    let placemark = item.placemark
                    
                    Annotation(placemark.name ?? "", coordinate: placemark.coordinate, anchor: .bottom) {
                        MapForkKnifePinIcon(image: Image(systemName: "fork.knife"), startColor: Color(red: 0.99, green: 0.69, blue: 0.28), endColor: Color(red: 0.96, green: 0.44, blue: 0.18))
                    }
//                    Annotation(placemark.name ?? "",
//                               coordinate: placemark.coordinate,
//                               anchor: .bottom) {
//                        BalloonPin(size: 34, fill: .indigo) {
//                            Image("mapImageIcon")
//                                .resizable()
//                                .scaledToFit()
//                                .foregroundStyle(.white)
//                        }
//                    }
                    
                    
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

//
//                    Marker(coordinate: placemark.coordinate) {
//
//                        MapImageIcon(category: .restaurant)
//
//                    }
//
                    
//                    Marker(placemark.name ?? "", coordinate: placemark.coordinate)
//                        .tag(item)

//                        .tint(.pink)


//Colours that work default (1) Pink - for default (2)

   // .tint(Color.indigo)
