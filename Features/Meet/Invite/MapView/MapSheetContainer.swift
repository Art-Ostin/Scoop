//
//  MapSearchView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//

import SwiftUI
import MapKit

struct MapSheetContainer: View {
    @FocusState private var searchFocused: Bool
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    @Binding var useSelectedDetent: Bool
    let onExitSelection: (MapSheets) -> Void
    let selectedLocation: (MKMapItem) -> Void


    var body: some View {
        sheetContent
        .animation(.easeInOut(duration: 0.16), value: sheet)
        .animation(.easeInOut(duration: 0.22), value: vm.selectedMapItem != nil)
        // Keep keyboard + focus “linked” to large search mode.
        .task(id: shouldAutoFocusSearch) {
            if shouldAutoFocusSearch {
                await Task.yield()                 // wait until large content is in hierarchy
                await MainActor.run { searchFocused = true }
            } else {
                await MainActor.run { searchFocused = false }
            }
        }
        .onChange(of: vm.selectedMapItem) { _, newValue in
            if newValue != nil { searchFocused = false }
        }
    }
}

extension MapSheetContainer {
    @ViewBuilder
    private var sheetContent: some View {
        if let mapItem = vm.selectedMapItem {
            MapSelectionView(vm: vm, mapItem: mapItem, onExitSelection: onExitSelection, selectedLocation: selectedLocation)
        } else if useSelectedDetent /*&& sheet != .large*/ {
            selectedLoadingScreen
        } else {
            // Powerful way to flick between content use again (I.e. in ZStack and animate).
            ZStack(alignment: .top) {
                if sheet == .searchBar {
                    mapSearchBar
                }
                if sheet == .optionsAndSearchBar {
                    MapOptionsView(vm: vm, isFocused: $searchFocused, sheet: $sheet, useSelectedDetent: $useSelectedDetent)
                }
                if sheet == .large {
                    MapSearchView(vm: vm, sheet: $sheet, isFocused: $searchFocused, useSelectedDetent: $useSelectedDetent)
                }
            }
            .transition(.opacity)
        }
    }

    
    
    private var shouldAutoFocusSearch: Bool {
        sheet == .large && vm.selectedMapItem == nil && !useSelectedDetent
    }
    
    private var mapSearchBar: some View {
        HStack(spacing: 6) {
            MapSearchBar(isFocused: $searchFocused, vm: vm, sheet: $sheet)
            if !vm.searchText.isEmpty { DeleteSearchButton(vm: vm) }
        }
        .padding(.horizontal, 16)
    }
    
    private var selectedLoadingScreen: some View {
        VStack(spacing: 120) {
            HStack(spacing: 6) {
                MapSearchBar(isFocused: $searchFocused, vm: vm, sheet: $sheet)
                
                if !vm.searchText.isEmpty { DeleteSearchButton(vm: vm) }
            }
            .padding(.horizontal)
            .padding(.top, 48)

            VStack {
                ProgressView()
                    .tint(Color.grayText)
                
                Text("Searching...")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color.grayText)
            }
            
            Spacer()
        }
    }
}


enum MapSheets: CaseIterable, Equatable {
    case searchBar, optionsAndSearchBar, large


    static let searchDetent: PresentationDetent = .fraction(0.10)
    static let optionsDetent: PresentationDetent = .fraction(0.22)
    static let selectedDetent: PresentationDetent = .fraction(0.46)
    static let largeDetent: PresentationDetent = .large

    var detent: PresentationDetent {
        switch self {
        case .searchBar:           Self.searchDetent
        case .optionsAndSearchBar: Self.optionsDetent
        case .large:               Self.largeDetent
        }
    }

    static func detents(hasSelection: Bool) -> Set<PresentationDetent> {
        if hasSelection {
            return [searchDetent, optionsDetent, selectedDetent, largeDetent]
        } else {
            return [searchDetent, optionsDetent, largeDetent]
        }
    }

    static func from(detent: PresentationDetent) -> Self {
        switch detent {
        case searchDetent:  return .searchBar
        case optionsDetent: return .optionsAndSearchBar
        case selectedDetent:return .optionsAndSearchBar
        default:            return .large
        }
    }
}

/*
 
 MapOptionsView(vm: vm, isFocused: $searchFocused, sheet: $sheet, useSelectedDetent: $useSelectedDetent)
     .opacity(sheet == .optionsAndSearchBar ? 1 : 0)
     .allowsHitTesting(sheet == .optionsAndSearchBar)
 
 MapSearchView(vm: vm, sheet: $sheet, isFocused: $searchFocused, useSelectedDetent: $useSelectedDetent)
     .opacity(sheet == .large ? 1 : 0)
     .allowsHitTesting(sheet == .large)
 
 mapSearchBar
     .foregroundStyle(Color.black)
     .opacity(sheet == .searchBar ? 1 : 0)
     .allowsHitTesting(sheet == .searchBar)
     .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

 */
