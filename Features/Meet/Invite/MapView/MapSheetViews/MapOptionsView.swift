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
            MapSearchBar(isFocused: $isFocused, vm: vm, sheet: $sheet)
                .padding(.horizontal, 16)
            
            mapCategoryIcons
                .padding(.horizontal, 24) //Adjusted as require wide frame for updating 
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
    
    private var mapCategoryIcons: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 64) {
                ClearRectangle(size: 36)
                ForEach(MapCategory.allCases) { category in
                    MapCategoryIcon(sheet: $sheet, category: category, isMap: true, vm: vm)
                }
            }
        }
    }
}

/*
 
 
 
 HStack {
     MapCategoryIcon(sheet: $sheet, style: .drink, isMap: true, vm: vm)
     Spacer()
     MapCategoryIcon(sheet: $sheet, style: .food, isMap: true, vm: vm)
     Spacer()
     MapCategoryIcon(sheet: $sheet, style: .cafe, isMap: true, vm: vm)
 }

 */

/*
 if vm.selectedMapCategory != nil {
     ClearIcon(vm: vm)
 }

 */
