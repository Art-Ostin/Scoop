//
//  Map Icons.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI

enum MapIconStyle: CaseIterable, Identifiable {
    
    case drink, food, cafe
    
    var id: Self { self }
    
    struct Spec {
        let startColor: Color
        let endColor: Color
        let imageLarge: Image
        let imageSmall: Image
        let description: String
    }
    
    private var spec: Spec {
        switch self {
        case .drink:
            return .init(
                startColor: Color(red: 1, green: 0.51, blue: 0.75),
                endColor:   Color(red: 0.86, green: 0.11, blue: 0.53),
                imageLarge: Image("CocktailIcon"),
                imageSmall: Image("DiscoBall"),
                description: "Drinks"
            )
            
        case .food:
            return .init(
                startColor: Color(red: 0.99, green: 0.69, blue: 0.28),
                endColor:   Color(red: 0.96, green: 0.44, blue: 0.18),
                imageLarge: Image("ForkSpoon"),
                imageSmall: Image(systemName: "fork.knife"),
                description: "Food"
            )
            
        case .cafe:
            return .init(
                startColor: Color(red: 0.28, green: 0.69, blue: 1),
                endColor:   Color(red: 0, green: 0.36, blue: 0.85),
                imageLarge: Image("CafeIcon"),
                imageSmall: Image(systemName: "cup.and.saucer.fill"),
                description: "Cafes"
            )
        }
    }
    
    var startColor: Color { spec.startColor }
    var endColor: Color { spec.endColor }
    var imageLarge: Image { spec.imageLarge }
    var imageSmall: Image { spec.imageSmall }
    var description: String { spec.description }

    var gradient: LinearGradient {
        LinearGradient(colors: [startColor, endColor], startPoint: .top, endPoint: .bottom)
    }
}

struct MapCategoryIcon: View {
    let style: MapIconStyle
    let isMap: Bool
    var size: CGFloat { isMap ? 60 : 30 }
    
    @Bindable var vm: MapViewModel
    
    var isSelected: Bool { vm.categorySearchText == style.description }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                vm.categorySearchText = style.description
            }
        } label : {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(style.gradient)
                        .frame(width: size, height: size)

                    (isMap ? style.imageLarge : style.imageSmall)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.white)
                        .font(.system(size: size * 0.55, weight: .semibold))
                        .scaleEffect(isMap ? 0.95 : 1)
                }
                .shadow(color: isSelected ? .black.opacity(0.22) : .clear, radius: 10, x: 0, y: 6)

                Text(style.description)
                    .font(.body(12, .bold))
                    .foregroundStyle(isSelected ? .accent : Color.grayText.opacity(0.8))
            }
        }
    }
}
