//
//  MapSearchBar.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI
import MapKit

struct MapSearchBar: View {
    
    @FocusState.Binding var isFocused: Bool
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    
    
    var body: some View {
            TextField("",text: $vm.searchText, prompt: searchPrompt)
                .padding(.horizontal, 40) //Geometry: clears the leading icon & trailing clear-button overlays
                .font(.system(size: 17))
                .frame(height: 45)
                .foregroundStyle(Color.textPrimary)
                .buttonBackground(.capsule, color: .clear)
                .contentShape(Capsule())
                .focused($isFocused)
                .simultaneousGesture(TapGesture().onEnded {
                    if sheet != .large { sheet = .large }
                })
                .onSubmit(of: .text) { Task { await searchAndSelectFirst() } }
                // Overlays sit ABOVE the tap gesture, not inside it: the clear button is a
                // sibling of the bar, so tapping it can't also expand the sheet.
                .overlay(alignment: .leading) { searchIcon }
                .overlay(alignment: .trailing) { deleteSearchButton }
                .animation(.toggle, value: vm.searchText.isEmpty)
        }
    }
extension MapSearchBar {
    
    private var searchPrompt: Text {
        Text("Search Maps")
            .foregroundStyle(Color.black.opacity(0.6))
            .font(.system(size: 16, weight: .medium))
    }
    
    private var searchIcon: some View {
        Image(systemName: "magnifyingglass")
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color.textPrimary)
            .padding(.leading, Spacing.sm)
            .allowsHitTesting(false) //Taps on the icon belong to the bar underneath
    }
        
    @ViewBuilder
    private var deleteSearchButton: some View {
        if !vm.searchText.isEmpty {
            Button {
                vm.clearSearch()
            } label : {
                Image(systemName: "xmark")
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.white)
                    .padding(Spacing.xxs)
                    .background (
                        Circle()
                            .foregroundStyle(Color.blackFill)
                    )
                    .scaleEffect(0.8)
                    .padding(.horizontal, Spacing.sm)
            }
        }
    }
    
    private func searchAndSelectFirst() async {
        await vm.searchPlaces()
        let first = vm.results.first
        await MainActor.run {
            if let first { vm.selection = MapSelection(first) }
        }
    }

}
