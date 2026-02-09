//
//  MapSearchView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//

import SwiftUI
import MapKit

struct MapSheetContainer: View {
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    let selectedLocation: (MKMapItem) -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        Group {
            if let mapItem = vm.selectedMapItem {
                MapSelectionView(vm: vm, mapItem: mapItem) { selectedLocation($0) }
            } else {
                switch sheet {
                case .searchBar:
                    MapSearchBar(isFocused: $searchFocused, vm: vm, sheet: $sheet)
                        .padding(.horizontal)
                    
                case .large:
                    MapSearchView(vm: vm, sheet: $sheet, isFocused: $searchFocused)

                default:
                    MapOptionsView(vm: vm, isFocused: $searchFocused, sheet: $sheet)
                }
            }
        }
        // Keep keyboard + focus “linked” to large search mode.
        .task(id: sheet) {
            await MainActor.run { searchFocused = false }
            guard sheet == .large, vm.selectedMapItem == nil else { return }
            await Task.yield()
            await MainActor.run { searchFocused = true }
        }
        .onChange(of: vm.selectedMapItem) { _, newValue in
            if newValue != nil { searchFocused = false }
        }
    }
}


enum MapSheets: CaseIterable, Equatable {
    case searchBar, optionsAndSearchBar, selected, large

    static let searchDetent: PresentationDetent = .fraction(0.10)
    static let optionsDetent: PresentationDetent = .fraction(0.22)
    static let selectedDetent: PresentationDetent = .fraction(0.42)
    static let largeDetent: PresentationDetent = .large

    var detent: PresentationDetent {
        switch self {
        case .searchBar:           Self.searchDetent
        case .optionsAndSearchBar: Self.optionsDetent
        case .selected:            Self.selectedDetent
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

    static func from(detent: PresentationDetent, hasSelection: Bool = true) -> Self {
        switch detent {
        case searchDetent:  return .searchBar
        case optionsDetent: return .optionsAndSearchBar
        case selectedDetent:return hasSelection ? .selected : .optionsAndSearchBar
        default:            return .large
        }
    }
}

