//
//  MapSearchView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//

import SwiftUI
import MapKit
import UIKit

struct MapSheetContainer: View {
    @FocusState private var compactSearchFocused: Bool
    @FocusState private var largeSearchFocused: Bool
    @State private var searchService = LocationSearchService()
    @State private var focusTask: Task<Void, Never>?
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
                        MapSearchBar(isFocused: $compactSearchFocused, vm: vm, sheet: $sheet, promoteToLargeOnTap: true)
                        if !vm.searchText.isEmpty { DeleteSearchButton(vm: vm) }
                    }
                    .padding(.horizontal)
                default:
                    ZStack(alignment: .top) {
                        
                        MapSearchView(service: searchService, vm: vm, sheet: $sheet, isFocused: $largeSearchFocused, useSelectedDetent: $useSelectedDetent)
                            .opacity(sheet == .large ? 1 : 0)
                            .allowsHitTesting(sheet == .large)

                        
                        
                        MapOptionsView(vm: vm, isFocused: $compactSearchFocused, sheet: $sheet, useSelectedDetent: $useSelectedDetent)
                            .opacity(sheet == .optionsAndSearchBar ? 1 : 0)
                            .allowsHitTesting(sheet == .optionsAndSearchBar)

                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.16), value: sheet)
        // Keep keyboard + focus “linked” to large search mode without stalling the detent snap.
        .onChange(of: sheet) { _, newSheet in
            setFocus(for: newSheet)
        }
        .onChange(of: vm.selectedMapItem) { _, newValue in
            if newValue != nil {
                focusTask?.cancel()
                compactSearchFocused = false
                largeSearchFocused = false
            }
        }
        .onDisappear {
            focusTask?.cancel()
        }
    }
}

extension MapSheetContainer {
    private func setFocus(for newSheet: MapSheets) {
        focusTask?.cancel()
        guard newSheet == .large, vm.selectedMapItem == nil, !useSelectedDetent else {
            dismissKeyboard()
            compactSearchFocused = false
            largeSearchFocused = false
            return
        }

        compactSearchFocused = false
        focusTask = Task {
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard sheet == .large, vm.selectedMapItem == nil else { return }
                largeSearchFocused = true
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    
    private var selectedLoadingScreen: some View {
        VStack(spacing: 120) {
            HStack(spacing: 6) {
                MapSearchBar(isFocused: $compactSearchFocused, vm: vm, sheet: $sheet, promoteToLargeOnTap: true)
                
                
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
