//
//  MapSearchBarOptions.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI

struct MapOptionsView: View {

    @Bindable var vm: MapViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            MapSearchBar(vm: vm)
            mapCategoryIcons
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
    
    private var mapCategoryIcons: some View {
        HStack {
            MapCategoryIcon(style: .drink, isMap: true)
            Spacer()
            MapCategoryIcon(style: .food, isMap: true)
            Spacer()
            MapCategoryIcon(style: .cafe, isMap: true)
        }
    }
}
