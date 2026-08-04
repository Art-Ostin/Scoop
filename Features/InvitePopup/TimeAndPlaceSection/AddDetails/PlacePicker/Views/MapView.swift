//
//  MapView.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2025.
//

import SwiftUI
import MapKit


struct MapView: View {
    
    @State var vm: MapViewModel

    @Environment(\.dismiss) var dismiss

    @Binding var eventLocation: EventLocation?

    @State private var sheet: MapSheets = .large

    @State private var sheetPresented = false
    @State private var sheetFlightEnded = false

    @State private var useSelectedDetent =  false
    @State private var isExitingSelectedSheet = false
    @State private var selectedSheetExitTask: Task<Void, Never>?

    private let selectedSheetTransitionDuration: TimeInterval = 0.12
    
    init(defaults: DefaultsManaging, eventLocation: Binding<EventLocation?>) {
        self._vm = State(initialValue: MapViewModel(defaults: defaults))
        self._eventLocation = eventLocation
    }
    
    private var detentSelection: Binding<PresentationDetent> {
        Binding(
            get: {
                if !isExitingSelectedSheet, (vm.selectedMapItem != nil || useSelectedDetent) {
                    return MapSheets.selectedDetent
                }
                return sheet.detent
            }, set: { newDetent in
                if vm.selectedMapItem != nil {
                    if newDetent != MapSheets.selectedDetent {
                        transitionFromSelectedSheet(
                            to: (newDetent == MapSheets.largeDetent) ? .large : .optionsAndSearchBar
                        )
                    }
                    return
                }
                
                if useSelectedDetent && newDetent != MapSheets.selectedDetent {
                    useSelectedDetent = false
                }
                withAnimation(.quick) {
                    sheet = MapSheets.from(detent: newDetent)
                }
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
                    
                    if vm.selectedMapCategory == .food || vm.selectedMapCategory == .pub || vm.selectedMapCategory == .park  {
                        let isSelected = vm.selectedMapItem == item
                        if let category = vm.selectedMapCategory  {
                            Annotation(item.placemark.name ?? "", coordinate: item.placemark.coordinate) {
                                CustomMapAnnotation(vm: vm, item: item, category: category, isSelected: isSelected)
                                    .zIndex(isSelected ? 1000 : -100)
                            }
                            .tag(MapSelection(item))
                        }
                    } else {
                        Marker(item: item)
                            .tag(MapSelection(item))
                            .tint(vm.markerTint)
                    }
                }
            }
            .mapControlVisibility(.visible)
            .onMapCameraChange(frequency: .continuous) { context in
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
            .overlay(alignment: .topTrailing) { DismissButton(type: .cross).padding(.horizontal, 16) }
            .onAppear { vm.locationManager.requestWhenInUseAuthorization() }
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                var tx = Transaction()
                tx.disablesAnimations = true
                withTransaction(tx) { sheetPresented = true }
            }
            .onChange(of: vm.selection) { _, newSelection in itemSelected(newSelection) }
            .onChange(of: vm.selectedMapItem) { _, newItem in
                if newItem != nil {
                    selectedSheetExitTask?.cancel()
                    isExitingSelectedSheet = false
                    useSelectedDetent = false
                }
            }
            .onChange(of: vm.selectedMapCategory) { _, newCategory in
                if newCategory == nil, !isExitingSelectedSheet {
                    useSelectedDetent = false
                }
            }
            .onDisappear { selectedSheetExitTask?.cancel() }
            .animation(.toggle, value: vm.selection)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: $sheetPresented) { mapSheet }
            .animation(.transition, value: useSelectedDetent)
            .overlay(alignment: .bottomTrailing) {
                GeometryReader { proxy in
                    actionMenu(containerHeight: proxy.size.height, bottomSafeArea: proxy.safeAreaInsets.bottom)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }

            if !sheetFlightEnded {
                MapSheetFlight(vm: vm, sheet: $sheet, useSelectedDetent: $useSelectedDetent)
            }
        }
        .mapScope(mapScope) //Fixes bug to allow it to apear (Need ZStack)
        .tint(.blue)
    }
}

extension MapView {

    
    //Clear a selected Category
    private var clearIcon: some View {
        
        
        ScoopButton(style: .clearGlass, shape: .capsule) {
            
        } label: {
            Text("Clear")
        }
    }
    
    
    private var pointsOfInterest: [MKPointOfInterestCategory] {
        [.nightlife, .restaurant, .beach, .brewery, .cafe, .bakery, .distillery,
         .winery, .foodMarket, .fairground, .landmark, .park, .musicVenue,
         .rockClimbing, .skating, .museum, .movieTheater, .amusementPark,
         .stadium, .bowling, .miniGolf, .zoo, .aquarium,
        ]
    }
    
    @ViewBuilder
    private var mapSheet: some View {
        MapSheetContainer(
            vm: vm,
            sheet: $sheet,
            useSelectedDetent: $useSelectedDetent,
            onExitSelection: transitionFromSelectedSheet
        ) { mapItem in
            eventLocation = EventLocation(mapItem: mapItem)
            dismiss()
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            //Teaches the flight twin exactly where this sheet sits on this device.
            if !sheetFlightEnded { MapSheetFlight.recordSheetFrame(frame) }
        }
        .task {
            //The flight twin below is redundant one rendered frame after this real sheet appears.
            try? await Task.sleep(for: .milliseconds(150))
            sheetFlightEnded = true
        }
        .presentationDetents(MapSheets.detents(hasSelection: vm.selectedMapItem != nil || useSelectedDetent), selection: detentSelection)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .interactiveDismissDisabled(true)
    }
    
    private func transitionFromSelectedSheet(to destination: MapSheets) {
        selectedSheetExitTask?.cancel()
        
        withAnimation(.quick) {
            vm.selection = nil
            vm.selectedMapItem = nil
            isExitingSelectedSheet = true
            useSelectedDetent = true
            sheet = destination
        }
        
        let delay = UInt64((selectedSheetTransitionDuration * 200_000_000).rounded())
        selectedSheetExitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            
            withAnimation(.quick) {
                useSelectedDetent = false
                isExitingSelectedSheet = false
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

                let base = lastCamera ?? MapCamera(centerCoordinate: coord, distance: 2500, heading: 0, pitch: 0)
                //Auto-selected search results fly home to a readable zoom; manual pin taps keep the user's zoom.
                let distance = vm.lastSelectionWasAutomatic ? min(base.distance, 4500) : base.distance
                vm.lastSelectionWasAutomatic = false
                let center = offsetCenter(for: coord, heading: base.heading, targetDistance: distance)
                // Exit user-follow mode before centering the selected place.
                vm.cameraPosition = .camera(base)
                camTarget = MapCamera(centerCoordinate: center, distance: distance, heading: base.heading, pitch: base.pitch)
                camDuration = (distance < 1500) ? 1.0 : 0.85
                camTrigger &+= 1
            }
        }
    }
    
    private func actionMenu(containerHeight: CGFloat, bottomSafeArea: CGFloat) -> some View {
        HStack {
            mapsButton
            Spacer()
            userLocationButton
        }
        .padding(.bottom, actionMenuBottomPadding(containerHeight: containerHeight, bottomSafeArea: bottomSafeArea))
        .padding(.horizontal, sheet == .searchBar ? 24 : 12)
        .animation(.move, value: sheet)
    }
    
    private var mapsButton: some View {
        let isAppleMaps = vm.defaults.preferredMapType == .appleMaps
        
        return ScoopButton(shape: .circle, size: .large) {
            MapsRouter.openMaps(defaults: vm.defaults)
        } label: {
            VStack(spacing: isAppleMaps ? 2 : 3) {
                Image(isAppleMaps ? "AppleMapIcon" : "GoogleMapsIcon")
                Text("Maps")
                    .font(.body(9, .bold))
                    .foregroundStyle(Color.black.opacity(0.9))
            }
            .frame(width: 45, height: 45, alignment: .center)
            .offset(y: isAppleMaps ? 1 : -1)
        }
    }
    
    private var userLocationButton: some View {
        MapUserLocationButton(scope: mapScope)
            .buttonBorderShape(.circle)
            .tint(.blue)
    }
    
    private func actionMenuBottomPadding(containerHeight: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        let visibleHeight = containerHeight + bottomSafeArea

        switch sheet {
        case .searchBar:
            return (visibleHeight * 0.05) + 36
        case .optionsAndSearchBar:
            return (visibleHeight * 0.17) + 48
        case .large:
            return 184
        }
    }
    
    private func offsetCenter(for coordinate: CLLocationCoordinate2D, heading: CLLocationDirection, targetDistance: Double) -> CLLocationCoordinate2D {
        let offsetRatio = 0.15
        let headingRadians = heading * .pi / 180

        //When the flight changes zoom, offset by the span the camera will LAND at, not the one it left.
        let span: MKCoordinateSpan
        if let lastCamera, targetDistance < lastCamera.distance {
            let delta = lastSpan.latitudeDelta * (targetDistance / lastCamera.distance)
            span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        } else {
            span = lastSpan
        }

        let latitudeOffset = span.latitudeDelta * offsetRatio
        let longitudeOffset = span.longitudeDelta * offsetRatio

        return CLLocationCoordinate2D(
            latitude: coordinate.latitude - (latitudeOffset * cos(headingRadians)),
            longitude: coordinate.longitude - (longitudeOffset * sin(headingRadians))
        )
    }
}

