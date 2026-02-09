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

    
    @State private var sheet: MapSheets = .optionsAndSearchBar
    
    private var detentSelection: Binding<PresentationDetent> {
        Binding(
            get: {
                if vm.selectedMapItem != nil {
                    return MapSheets.selectedDetent
                }
                return sheet.detent
            }, set: { newDetent in
                
                if vm.selectedMapItem != nil {
                    if newDetent != MapSheets.selectedDetent {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            sheet = (newDetent == MapSheets.largeDetent) ? .large : .optionsAndSearchBar
                            vm.selectedMapItem = nil
                            vm.selection = nil
                        }
                    }
                    return
                }
                sheet = MapSheets.from(detent: newDetent)
            }
        )
    }
    
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
            .mapControls{}
            .mapStyle(.standard(pointsOfInterest: .including(pointsOfInterest)))
            .overlay(alignment: .topTrailing) { DismissButton() {dismiss()} }
            .onAppear {vm.locationManager.requestWhenInUseAuthorization() }
            .onChange(of: vm.selection) { _, newSelection in itemSelected(newSelection) }
            .animation(.easeInOut(duration: 0.3), value: vm.selection)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: .constant(true)) { mapSheet }
            .overlay(alignment: .bottomTrailing) {userLocationButton}
        }
        .mapScope(mapScope) //Fixes bug to allow it to apear (Need ZStack)
    }
}


extension MapView {
    
    private var pointsOfInterest: [MKPointOfInterestCategory] {
        [.nightlife, .restaurant, .beach, .brewery, .cafe, .distillery,
         .foodMarket, .fairground, .landmark, .park, .musicVenue,
         .rockClimbing, .skating,
                 
        ]
    }
    
    @ViewBuilder
    private var mapSheet: some View {
        MapSheetContainer(vm: vm, sheet: $sheet) { mapItem in
            eventVM.event.location = EventLocation(mapItem: mapItem)
        }
        .presentationDetents(MapSheets.detents(hasSelection: vm.selectedMapItem != nil), selection: detentSelection)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .interactiveDismissDisabled(true)
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
            }
        }
    }
    
    private var userLocationButton: some View {
        MapUserLocationButton(scope: mapScope)
            .buttonBorderShape(.circle)
            .tint(.blue)
            .padding(.bottom, 96)
            .offset(y: -48)
    }
}
