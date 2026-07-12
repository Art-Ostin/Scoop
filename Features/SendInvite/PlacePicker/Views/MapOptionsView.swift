//
//  MapSearchBarOptions.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI

struct MapOptionsView: View {

    @Bindable var vm: MapViewModel
    @FocusState.Binding var isFocused: Bool
    @Binding var sheet: MapSheets
    
    @Binding var  useSelectedDetent: Bool
    @State private var scrollPos = ScrollPosition(idType: MapCategory.self)

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.xs) {
                MapSearchBar(isFocused: $isFocused, vm: vm, sheet: $sheet)

                if !vm.searchText.isEmpty { DeleteSearchButton(vm: vm) }
            }
            .padding(.horizontal, Spacing.gutter)
            
            mapCategoryIcons
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, Spacing.md)
    }
    
    private var mapCategoryIcons: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xl) {
                ForEach(MapCategory.allCases) { category in
                    if category != .park {
                        MapCategoryIcon(sheet: $sheet, category: category, isMap: true, vm: vm, useSelectedDetent: $useSelectedDetent)
                            .id(category)
                    }
                }
            }
            .scrollTargetLayout()
            .offset(x: -12)
        }
        .contentMargins(.horizontal, Spacing.xl)
        .scrollPosition($scrollPos)
        .onAppear {
            guard let selected = vm.selectedMapCategory, MapCategory.allCases.contains(selected) else {return }
            scrollPos.scrollTo(id: selected, anchor: .center)
        }
        .scrollIndicators(.never)
        .customHorizontalScrollFade(width: 40, showFade: true, fromLeading: true)
        .customHorizontalScrollFade(width: 40, showFade: true, fromLeading: false)
    }
    
    private var deleteSearchButton: some View {
        // TEMP: glass button commented out for ButtonTest preview
        EmptyView()
        /*
        GlassButton(padding: 6) {
            vm.searchText = ""
            vm.selectedMapCategory = nil
        } buttonLabel: {
            Image(systemName: "xmark")
                .font(.body(18, .bold))
        }
        */
    }
}

struct DeleteSearchButton: View {
    @Bindable var vm: MapViewModel
    
    var body: some View {
            // TEMP: glass button commented out for ButtonTest preview
            EmptyView()
            /*
            GlassButton(padding: 6) {
                vm.searchText = ""
                vm.selectedMapCategory = nil
            } buttonLabel: {
                Image(systemName: "xmark")
                    .font(.body(18, .bold))
            }
            */
    }
}
