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
     
     
     var body: some View {
         
         Map(position: $vm.cameraPosition, selection: $vm.mapSelection) {
                 UserAnnotation()
                 
                 ForEach(vm.results, id: \.self) { item in
                     let placemark = item.placemark
                     Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                 }
             }
             .mapControls {
                 MapUserLocationButton()
             }
             .onAppear {
               vm.locationManager.requestWhenInUseAuthorization()
             }
             .overlay(alignment: .top) {
                 MapSearchView(vm: vm)
             }
             .overlay(alignment: .topTrailing) {
                 Button {
                     dismiss()
                 } label: {
                     Image(systemName: "xmark")
                         .frame(width: 40, height: 40)
                         .clipShape(Circle())
                         .background(Color.white)
                         .padding()
                 }
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
         
             .tint(Color.blue)
         
     }
 }

// #Preview {
//     MapView( selectedPlace: .constant(nil))
// }
