//
//  MapCategoryIcon.swift
//  Scoop
//
//  Created by Art Ostin on 10/02/2026.
//

import SwiftUI
import Lottie

struct MapCategoryIcon: View {
    
    @State var hitMaxSearches: Bool = false
    @Binding var sheet: MapSheets
    
    var showHitMaxSearch: Bool { hitMaxSearches && isSelected}
    let category: MapCategory
    let isMap: Bool
    var size: CGFloat { isMap ? 60 : 35 }

    @Bindable var vm: MapViewModel
    @Binding var useSelectedDetent: Bool
    
    var isSelected: Bool { vm.selectedMapCategory == category }
    var showLoading: Bool { isSelected && vm.isLoadingCategory}
    
    
    private var showSearchArea: Bool {
        isMap
        && isSelected
        && vm.lastSearchRegion != nil
        && vm.hasMovedSinceSearch()
    }
    var body: some View {
        Button {
            vm.selectedMapCategory = category
            if isMap {
               useSelectedDetent = true 
            } else {
                sheet = .searchBar
            }
        } label : {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.gradient)
                        .frame(width: size, height: size)
                    
                    if !showLoading {
                        category.image
                            .scaleEffect(isMap ? 0.95 : 0.55)
                            .offset(x: category == .pub ? 1 : 0)
                    }
                }
                .shadow(color: isSelected && isMap ? .black.opacity(0.22) : .clear, radius: 10, x: 0, y: 6)
                .foregroundStyle(Color.white) //For the systemNameIcons
                .font(.body(20))

                if isMap {
                    Group {
                        if showSearchArea {
                            Text("Search Area")
                        } else {
                            Text(category.description)
                        }
                    }
                    .font(.body(12, .bold))
                    .frame(width: 75)
                    .foregroundStyle(isSelected && !showLoading ? Color.accent : Color.grayText.opacity(0.8))
                    .animation(.easeInOut(duration: 0.3), value: showLoading)
                }
            }
            .overlay(alignment: .center) {
                if isMap {
                    if showLoading {
                        LottieView(animation: .named("ModernMiniLoaderBlue.json"))
                            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .offset(y: -12)
                    }
                }
            }
        }
//        .id(vm.selectedMapCategory)
    }
}

