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
                
                if !vm.searchText.isEmpty { deleteSearchButton }
            }
            .padding(.horizontal, 16)
            
            mapCategoryIcons

        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
    
    private var mapCategoryIcons: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 36) {
                ClearRectangle(size: 0)
                ForEach(MapCategory.allCases) { category in
                    if category != .park {
                        MapCategoryIcon(sheet: $sheet, category: category, isMap: true, vm: vm)
                    }
                }
                ClearRectangle(size: 0)
            }
            .offset(x: -12)
        }
        .scrollIndicators(.never)
        .customHorizontalScrollFade(width: 40, showFade: true, fromLeading: true)
        .customHorizontalScrollFade(width: 40, showFade: true, fromLeading: false)

    }
    
    private var deleteSearchButton: some View {
        Button {
            vm.searchText = ""
            vm.selectedMapCategory = nil
        } label: {
            Image(systemName: "xmark")
                .font(.body(18, .bold))
                .frame(width: 45, height: 45)
                .glassIfAvailable(Circle())
                .contentShape(Circle())
                .foregroundStyle(Color.black)
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
