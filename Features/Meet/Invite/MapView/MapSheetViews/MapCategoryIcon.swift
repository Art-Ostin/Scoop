//
//  Map Icons.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI
import Lottie

enum MapCategory: CaseIterable, Identifiable {
    
    case restaurant, cafe, bar, pub, club, park, activity
    
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
            
        //Yellow
        case .restaurant:
            return .init(
                startColor: Color(red: 1, green: 0.51, blue: 0.75),
                endColor:   Color(red: 0.86, green: 0.11, blue: 0.53),
                mainColor:  Color(red: 0.89, green: 0.09, blue: 0.55),
                image: Image("ForkSpoon"),
                description: "Restaurant"
            )
            
        //Blue DONE
        case .cafe:
            return .init(
                startColor: Color(red: 0.28, green: 0.69, blue: 1),
                endColor:   Color(red: 0, green: 0.36, blue: 0.85),
                mainColor:  Color(.blue),
                image: Image("CafeIcon"),
                description: "Cafes"
            )
            
            
        //purple DONE
        case .bar:
            return .init(
                startColor: Color(red: 1, green: 0.51, blue: 0.75),
                endColor:   Color(red: 0.86, green: 0.11, blue: 0.53),
                mainColor:  Color(red: 0.89, green: 0.09, blue: 0.55),
                image: Image("CocktailIcon"),
                description: "Drinks"
            )
            
        //Orange DONE
        case .pub:
            return .init(
                startColor: Color(red: 0.99, green: 0.69, blue: 0.28),
                endColor:   Color(red: 0.96, green: 0.44, blue: 0.18),
                mainColor: Color(red: 1, green: 0.28, blue: 0),
                image: Image("ForkSpoon"),
                description: "Food"
            )
            
        //Purple DONE
        case .club:
            return .init(
                startColor: Color(red: 1, green: 0.51, blue: 0.75),
                endColor:   Color(red: 0.86, green: 0.11, blue: 0.53),
                mainColor:  Color(red: 0.89, green: 0.09, blue: 0.55),
                image: Image("DiscoBallLarge"),
                description: "Clubs"
            )
            
        //Green
        case .park:
            return .init(
                startColor: Color(red: 1, green: 0.51, blue: 0.75),
                endColor:   Color(red: 0.86, green: 0.11, blue: 0.53),
                mainColor:  Color(red: 0.89, green: 0.09, blue: 0.55),
                image: Image("DiscoBallLarge"),
                description: "Clubs"
            )


        //Blue (dark)
        case .activity:
            return .init(
                startColor: Color(red: 1, green: 0.51, blue: 0.75),
                endColor:   Color(red: 0.86, green: 0.11, blue: 0.53),
                mainColor:  Color(red: 0.89, green: 0.09, blue: 0.55),
                image: Image("DiscoBallLarge"),
                description: "Clubs"
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
    
    @State var hitMaxSearches: Bool = false
    @Binding var sheet: MapSheets
    
    var showHitMaxSearch: Bool { hitMaxSearches && isSelected}
    
    let category: MapCategory
    let isMap: Bool
    var size: CGFloat { isMap ? 60 : 35 }
    
    var shouldShowSearchArea: Bool { isSelected && vm.hasMovedEnoughToRefreshSearch }

    @Bindable var vm: MapViewModel
    
    var isSelected: Bool { vm.selectedMapCategory == category }
    
    var showLoading: Bool { isSelected && vm.isLoadingCategory}
    
    
    var body: some View {
        Button {
            if !isMap {sheet = .searchBar}
            vm.selectedMapCategory = category
        } label : {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.gradient)
                        .frame(width: size, height: size)
                    
                    if !showLoading {
                        category.image
                            .scaleEffect(isMap ? 0.95 : 0.55)
                    }
                }
                .shadow(color: isSelected && !isMap ? .black.opacity(0.22) : .clear, radius: 10, x: 0, y: 6)
                
                if isMap {
                    Group {
                        if shouldShowSearchArea && !showLoading && !showHitMaxSearch { // If the user has moved map location sufficiently
                            Text ("Search Area")
                        } else {
                            if showHitMaxSearch {
                                Text("Wait 30s")
                            } else {
                                Text(category.description)
                            }
                        }
                    }
                    .font(.body(12, .bold))
                    .frame(width: 75)
                    .foregroundStyle(isSelected && !showLoading ? Color.black : Color.grayText.opacity(0.8))
                    .animation(.easeInOut(duration: 0.3), value: shouldShowSearchArea)
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
        .id(vm.selectedMapCategory)
    }
}
