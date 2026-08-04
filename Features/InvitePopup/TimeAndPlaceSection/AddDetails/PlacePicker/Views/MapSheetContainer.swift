//
//  MapSheetContainer.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2025.
//

import SwiftUI
import MapKit

struct MapSheetContainer: View {
    //Injected
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    @Binding var useSelectedDetent: Bool
    let onExitSelection: (MapSheets) -> Void
    let selectedLocation: (MKMapItem) -> Void

    //Local view state
    @FocusState private var searchFocused: Bool
    @State private var entranceFocusDone = false
    @State private var emptySearchExitTask: Task<Void, Never>?

    private let keyboardOpenDelay: Duration = .milliseconds(50)
    private let emptySearchNoticeDuration: TimeInterval = 1.4

    var body: some View {
        sheetContent
        .animation(.transition, value: sheet)
        .animation(.transition, value: vm.selectedMapItem != nil)

        // Keep keyboard + focus “linked” to large search mode; the first focus of the
        // entrance holds back for keyboardOpenDelay so the platter leads the keyboard.
        .task(id: shouldAutoFocusSearch) {
            if shouldAutoFocusSearch {
                if entranceFocusDone {
                    await Task.yield()             // wait until large content is in hierarchy
                } else if (try? await Task.sleep(for: keyboardOpenDelay)) == nil {
                    return                         // entrance cancelled (sheet left large mode)
                }
                entranceFocusDone = true
                searchFocused = true
            } else {
                entranceFocusDone = true
                searchFocused = false
            }
        }
        .onChange(of: vm.selectedMapItem) { _, newValue in
            if newValue != nil { searchFocused = false }
        }
        .onChange(of: vm.searchFoundNothing) { _, foundNothing in
            emptySearchExitTask?.cancel()
            //Only the wedged loading sheet needs rescuing — a large-sheet typed search stays put.
            guard foundNothing, useSelectedDetent else { return }
            //Show "No Places Found Nearby" for a beat, then take the measured exit back to the category row.
            emptySearchExitTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(emptySearchNoticeDuration))
                guard !Task.isCancelled, useSelectedDetent, !searchFocused else { return }
                onExitSelection(.optionsAndSearchBar)
            }
        }
        .onChange(of: searchFocused) { _, focused in
            if focused { emptySearchExitTask?.cancel() } //Typing over the notice cancels the auto-exit
        }
        .onDisappear { emptySearchExitTask?.cancel() }
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
        HStack(spacing: Spacing.xs) {
            MapSearchBar(isFocused: $searchFocused, vm: vm, sheet: $sheet)
            if !vm.searchText.isEmpty { DeleteSearchButton(vm: vm) }
        }
        .padding(.horizontal, Spacing.gutter)
    }
    
    private var selectedLoadingScreen: some View {
        VStack(spacing: 120) { //Geometry: drops the spinner to mid-sheet while loading
            HStack(spacing: Spacing.xs) {
                MapSearchBar(isFocused: $searchFocused, vm: vm, sheet: $sheet)
                
                if !vm.searchText.isEmpty { DeleteSearchButton(vm: vm) }
            }
            .padding(.horizontal)
            .padding(.top, Spacing.xl)

            VStack {
                if vm.searchFoundNothing {
                    Text("No Places Found Nearby")
                        .font(.body(17, .medium))
                        .foregroundStyle(Color.textTertiary)
                } else {
                    ProgressView()
                        .tint(Color.textTertiary)

                    Text("Searching...")
                        .font(.body(17, .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .animation(.transition, value: vm.searchFoundNothing)

            Spacer()
        }
    }
}



//Different Screen Detents
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
        case searchDetent:  .searchBar
        case optionsDetent: .optionsAndSearchBar
        case selectedDetent: .optionsAndSearchBar
        default:            .large
        }
    }
}
