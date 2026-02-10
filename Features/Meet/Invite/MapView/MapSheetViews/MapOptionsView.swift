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
    
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 6) {
                MapSearchBar(isFocused: $isFocused, vm: vm, sheet: $sheet)
                if vm.selectedMapCategory != nil {
                    ClearIcon(vm: vm)
                }
            }
//            MapSearchBar(isFocused: $isFocused, vm: vm, sheet: $sheet)
            mapCategoryIcons
                .padding(.horizontal, 24) //Adjusted as require wide frame for updating 
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
    
    private var mapCategoryIcons: some View {
        HStack {
            MapCategoryIcon(sheet: $sheet, style: .drink, isMap: true, vm: vm)
            Spacer()
            MapCategoryIcon(sheet: $sheet, style: .food, isMap: true, vm: vm)
            Spacer()
            MapCategoryIcon(sheet: $sheet, style: .cafe, isMap: true, vm: vm)
        }
    }
}
