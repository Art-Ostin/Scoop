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
    
    
    @State private var currentDetent: PresentationDetent = .fraction(0.1)
    private let searchBarDetent: PresentationDetent = .fraction(0.1)
    private let optionsDetent: PresentationDetent = .fraction(0.25)
    private let selectedDetent: PresentationDetent = .fraction(0.42)
    
    
    let coordSpace = "MapSpace"
    
    
    //Deals with Camera Updates
    @State private var lastCamera: MapCamera?
    @State private var lastSpan: MKCoordinateSpan = .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
    @State private var camTarget: MapCamera?
    @State private var camTrigger: Int = 0
    @State private var camDuration: Double = 0.85
    
    @Namespace private var mapScope
    var body: some View {
        ZStack {
            Map(position: $vm.cameraPosition, selection: $vm.selection, scope: mapScope) {
                UserAnnotation()
                ForEach(vm.results, id: \.self) { item in
                    Marker(item: item)
                        .tag(MapSelection(item))
                        .tint(Color(red: 0.78, green: 0, blue: 0.35))
                }
            }
            .mapControlVisibility(.visible)
            .onMapCameraChange(frequency: .onEnd) { context in
                lastCamera = context.camera
                lastSpan = context.region.span
                vm.visibleRegion = context.region
            }
            .mapCameraKeyframeAnimator(trigger: camTrigger) { camera in
                let t = camTarget ?? camera
                KeyframeTrack(\MapCamera.centerCoordinate) {
                    CubicKeyframe(t.centerCoordinate, duration: camDuration)
                }
                KeyframeTrack(\MapCamera.distance) {
                    CubicKeyframe(t.distance, duration: camDuration)
                }
                KeyframeTrack(\MapCamera.heading) {
                    CubicKeyframe(t.heading, duration: camDuration)
                }
                KeyframeTrack(\MapCamera.pitch) {
                    CubicKeyframe(t.pitch, duration: camDuration)
                }
            }
            .mapControlVisibility(.hidden)
            .mapControls{
                
            }
            .mapStyle(.standard(pointsOfInterest: .including(pointsOfInterest)))
            .overlay(alignment: .topTrailing) { DismissButton() {dismiss()} }
            .onAppear {vm.locationManager.requestWhenInUseAuthorization() }
            .overlay(alignment: .top) { searchAreaButton }
            .onChange(of: vm.selection) { _, newSelection in itemSelected(newSelection) }
            .animation(.easeInOut(duration: 0.3), value: vm.selection)
            .sheet(isPresented: .constant(true)) {
                searchView
            }
            .overlay(alignment: .bottomTrailing) {
                MapUserLocationButton(scope: mapScope)
                    .buttonBorderShape(.circle)
                    .tint(.blue)
                    .padding(.bottom, 72)
                    .offset(y: -48)
            }
        }
        .mapScope(mapScope) //Fixes bug to allow it to apear (Need ZStack)
    }
}




/*
 
 */

extension MapView {
    
    private var pointsOfInterest: [MKPointOfInterestCategory] {
        [.nightlife, .restaurant, .beach, .brewery, .cafe, .distillery,
         .foodMarket, .fairground, .landmark, .park, .musicVenue,
         .rockClimbing, .skating,
                 
        ]
    }
    
    private var searchAreaButton: some View {
        Button {
            print("Tapped")
            Task { await vm.searchBarsInVisibleRegion() }
        } label: {
            Text("Search Area")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .glassIfAvailable(isClear: true, thinMaterial: true)
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
    }
    
    private var searchView: some View {
        MapSheet(vm: vm, currentDetent: $currentDetent) {mapItem in
            eventVM.event.location = EventLocation(mapItem: mapItem)
        }
        .presentationDetents([searchBarDetent, optionsDetent, selectedDetent, .large], selection: $currentDetent)
        .presentationBackgroundInteraction(.enabled(upThrough: selectedDetent))
        .interactiveDismissDisabled(true)
        .onChange(of: currentDetent) {oldValue, newValue in
            if oldValue == selectedDetent {
                vm.selectedMapItem = nil
                vm.selection = nil
            } else if oldValue == .large && vm.selectedMapItem == nil {
                self.currentDetent = searchBarDetent
            } else if oldValue == searchBarDetent && vm.selectedMapItem == nil {
                self.currentDetent = optionsDetent
            }
        }
    }
    
    private func itemSelected(_ newSelection: MapSelection<MKMapItem>?) {
        Task { @MainActor in
            await vm.updateSelectedMapItem(from: newSelection)
            guard !Task.isCancelled else { return }

            //Animation to update camera Position smoothly
            if let item = vm.selectedMapItem {
                let coord = item.placemark.coordinate
                let yOffset = lastSpan.latitudeDelta * 0.15
                let center = CLLocationCoordinate2D(latitude: coord.latitude - yOffset, longitude: coord.longitude)
                
                let base = lastCamera ?? MapCamera(centerCoordinate: center, distance: 2500, heading: 0, pitch: 0)
                camTarget = MapCamera(centerCoordinate: center, distance: base.distance, heading: base.heading, pitch: base.pitch)
                camDuration = (base.distance < 1500) ? 1.0 : 0.85
                camTrigger &+= 1
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentDetent = selectedDetent
                }
            } else {
                currentDetent = searchBarDetent
            }
        }
    }
}
