//
//  MapView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//

import SwiftUI
import MapKit


struct MapView: View {
    
    
    @State var  vm: MapViewModel
    
    @Environment(\.dismiss) var dismiss
    @Bindable var eventVM: TimeAndPlaceViewModel
    @State private var sheet: MapSheets = .optionsAndSearchBar
    
    @State var useSelectedDetent =  false
    @State private var isExitingSelectedSheet = false
    @State private var selectedSheetExitTask: Task<Void, Never>?
    
    private let selectedSheetTransitionDuration: TimeInterval = 0.3
    
    init(defaults: DefaultsManaging, eventVM: TimeAndPlaceViewModel) {
        self._vm = State(initialValue: MapViewModel(defaults: defaults))
        self._eventVM = Bindable(wrappedValue: eventVM)
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
                withAnimation(.easeInOut(duration: 0.15)) {
                    sheet = MapSheets.from(detent: newDetent)
                }
//                sheet = MapSheets.from(detent: newDetent)
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
            .overlay(alignment: .topTrailing) { DismissButton() {dismiss()} }
            .onAppear {vm.locationManager.requestWhenInUseAuthorization() }
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
            .animation(.easeInOut(duration: 0.3), value: vm.selection)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: .constant(true)) { mapSheet }
            .animation(.easeInOut(duration: 0.3), value: useSelectedDetent)
            .overlay(alignment: .bottomTrailing) {
                GeometryReader { proxy in
                    actionMenu(containerHeight: proxy.size.height, bottomSafeArea: proxy.safeAreaInsets.bottom)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
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
        MapSheetContainer(
            vm: vm,
            sheet: $sheet,
            useSelectedDetent: $useSelectedDetent,
            onExitSelection: transitionFromSelectedSheet
        ) { mapItem in
            eventVM.event.location = EventLocation(mapItem: mapItem)
            dismiss()
        }
        .presentationDetents(MapSheets.detents(hasSelection: vm.selectedMapItem != nil || useSelectedDetent), selection: detentSelection)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .interactiveDismissDisabled(true)
    }
    
    private func transitionFromSelectedSheet(to destination: MapSheets) {
        selectedSheetExitTask?.cancel()

        withAnimation(.easeInOut(duration: selectedSheetTransitionDuration)) {
            isExitingSelectedSheet = true
            useSelectedDetent = true
            sheet = destination
            vm.selection = nil
            vm.selectedMapItem = nil
        }
        
        let delay = UInt64((selectedSheetTransitionDuration * 100_000_000).rounded())
        selectedSheetExitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            
            withAnimation(.easeInOut(duration: 0.12)) {
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
                let yOffset = lastSpan.latitudeDelta * 0.15
                let center = CLLocationCoordinate2D(latitude: coord.latitude - yOffset, longitude: coord.longitude)
                
                let base = lastCamera ?? MapCamera(centerCoordinate: center, distance: 2500, heading: 0, pitch: 0)
                camTarget = MapCamera(centerCoordinate: center, distance: base.distance, heading: base.heading, pitch: base.pitch)
                camDuration = (base.distance < 1500) ? 1.0 : 0.85
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
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: sheet)
    }
    
    private var mapsButton: some View {
        Button {
            MapsRouter.openGoogleMaps()
        }
        label: {
            VStack(spacing: 3) {
                Image("GoogleMapsIcon")

                Text("Maps")
                    .font(.body(9, .bold))
                    .foregroundStyle(Color.black.opacity(0.9))
            }
            .frame(width: 45, height: 45, alignment: .center)
            .offset(y: -1)
            .glassIfAvailable(Circle(), isClear: false)
        }
    }
    
    
    private func actionMenuBottomPadding(containerHeight: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        let visibleHeight = containerHeight + bottomSafeArea

        switch sheet {
        case .searchBar:
            return (visibleHeight * 0.05) + 24
        case .optionsAndSearchBar:
            return (visibleHeight * 0.17) + 48
        case .large:
            return 184
        }
    }

    
    
    private var userLocationButton: some View {
        MapUserLocationButton(scope: mapScope)
            .buttonBorderShape(.circle)
            .tint(.blue)
    }
}
