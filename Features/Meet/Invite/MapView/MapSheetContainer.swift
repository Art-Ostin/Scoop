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
    let selectedLocation: (MKMapItem) -> Void


    var body: some View {
        Group {
            
            if let mapItem =  vm.selectedMapItem  {
                MapSelectionView(vm: vm, sheet: $sheet, mapItem: mapItem) { selectedLocation($0)}
            } else if useSelectedDetent {
                selectedLoadingScreen
            } else {
                switch sheet {
                case .searchBar:
                    HStack(spacing: 6) {
                        MapSearchBar(isFocused: $searchFocused, vm: vm, sheet: $sheet)
                        if !vm.searchText.isEmpty { DeleteSearchButton(vm: vm) }
                    }
                    .padding(.horizontal)

                case .large:
                    MapSearchView(vm: vm, sheet: $sheet, isFocused: $searchFocused, useSelectedDetent: $useSelectedDetent)

                default:
                    MapOptionsView(vm: vm, isFocused: $searchFocused, sheet: $sheet, useSelectedDetent: $useSelectedDetent)
                }
            }
        }
        // Keep keyboard + focus “linked” to large search mode.
        .task(id: sheet) {
            if sheet == .large, vm.selectedMapItem == nil {
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
    static let selectedDetent: PresentationDetent = .fraction(0.42)
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

