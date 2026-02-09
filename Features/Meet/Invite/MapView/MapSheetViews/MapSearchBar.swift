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
                .padding(.horizontal, 40)
                .font(.system(size: 17))
                .overlay(alignment: .leading) { searchIcon }
                .overlay(alignment: .trailing) {deleteSearchButton}
                .frame(height: 45)
                .glassIfAvailable(Capsule(), isClear: false)
                .contentShape(Capsule())
                .focused($isFocused)
                .simultaneousGesture(TapGesture().onEnded {
                    if sheet != .large { sheet = .large }
                })
                .onSubmit(of: .text) { Task { await searchAndSelectFirst() } }
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
            .foregroundStyle(.black)
            .padding(.leading, 12)
    }
        
    @ViewBuilder
    private var deleteSearchButton: some View {
        if !vm.searchText.isEmpty {
            Button {
                vm.searchText = ""
            } label : {
                Image(systemName: "xmark")
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.white)
                    .padding(4)
                    .background (
                        Circle()
                            .foregroundStyle(Color(red: 0.53, green: 0.53, blue: 0.56))
                    )
                    .scaleEffect(0.8)
                    .padding(.horizontal, 12)
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
