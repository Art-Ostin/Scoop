//
//  Map Icons.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI
import Lottie

enum MapIconStyle: CaseIterable, Identifiable {
    
    case drink, food, cafe
    
    var id: Self { self }
    
    struct Spec {
        let startColor: Color
        let endColor: Color
        let mainColor: Color
        let image: Image
        let description: String
    }
    
    private var spec: Spec {
        switch self {
        case .drink:
            return .init(
                startColor: Color(red: 1, green: 0.51, blue: 0.75),
                endColor:   Color(red: 0.86, green: 0.11, blue: 0.53),
                mainColor:  Color(red: 0.89, green: 0.09, blue: 0.55),
                image: Image("CocktailIcon"),
                description: "Drinks"
            )
            
        case .food:
            return .init(
                startColor: Color(red: 0.99, green: 0.69, blue: 0.28),
                endColor:   Color(red: 0.96, green: 0.44, blue: 0.18),
                mainColor: Color(red: 1, green: 0.28, blue: 0),
                image: Image("ForkSpoon"),
                description: "Food"
            )
            
        case .cafe:
            return .init(
                startColor: Color(red: 0.28, green: 0.69, blue: 1),
                endColor:   Color(red: 0, green: 0.36, blue: 0.85),
                mainColor:  Color(.blue),
                image: Image("CafeIcon"),
                description: "Cafes"
            )
        }
    }
    
    var startColor: Color { spec.startColor }
    var endColor: Color { spec.endColor }
    var mainColor: Color {spec.mainColor}
    var image: Image { spec.image }
    var description: String { spec.description }

    var gradient: LinearGradient {
        LinearGradient(colors: [startColor, endColor], startPoint: .top, endPoint: .bottom)
    }
}

struct MapCategoryIcon: View {
    
    let style: MapIconStyle
    let isMap: Bool
    var size: CGFloat { isMap ? 60 : 30 }
    
    var shouldShowSearchArea: Bool { isSelected && vm.hasMovedEnoughToRefreshSearch }

    @Bindable var vm: MapViewModel
    
    var isSelected: Bool { vm.selectedMapCategory == style }
    
    var showLoading: Bool { isSelected && vm.isLoadingCategory}
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                vm.selectedMapCategory = style
            }
        } label : {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(style.gradient)
                        .frame(width: size, height: size)
                    
                    if !showLoading {
                        style.image
                            .scaleEffect(isMap ? 0.95 : 0.55)
                    }
                }
                .shadow(color: isSelected ? .black.opacity(0.22) : .clear, radius: 10, x: 0, y: 6)
                
                Group {
                    if shouldShowSearchArea && !showLoading{ // If the user has moved location on the map sufficiently
                        Text ("Search Area")
                    } else {
                        Text(style.description)
                    }
                }
                .font(.body(12, .bold))
                .foregroundStyle(isSelected && !showLoading ? .accent : Color.grayText.opacity(0.8))
                .animation(.easeInOut(duration: 0.3), value: shouldShowSearchArea)
                .animation(.easeInOut(duration: 0.3), value: showLoading)
            }
            .overlay(alignment: .center) {
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
        .id(vm.selectedMapCategory)
    }
}

