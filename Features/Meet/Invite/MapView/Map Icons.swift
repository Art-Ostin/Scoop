//
//  Map Icons.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI

enum MapIconStyle {
    
    case drink, food, cafe
    
    
    var startColor: Color {
        switch self {
            
        //Pink
        case .drink:
            return Color(red: 1, green: 0.51, blue: 0.75)
            
        //Orange
        case .food:
            return  Color(red: 0.99, green: 0.69, blue: 0.28)

            
        //Blue
        case .cafe:
            return  Color(red: 0.28, green: 0.69, blue: 1)
        }
    }
    
    var endColor: Color {
        switch self {
            
        //Pink
        case .drink:
            return Color(red: 0.86, green: 0.11, blue: 0.53)

        case .food:
            return  Color(red: 0.96, green: 0.44, blue: 0.18)

        case .cafe:
            return  Color(red: 0, green: 0.36, blue: 0.85)
        }
    }
    
    var imageLarge: Image {
        switch self {
        case .drink:
            return Image("CocktailIcon")
            
        case .food:
            return Image("ForkSpoon")
            
        case .cafe:
            return Image("CafeIcon")
        }
    }
    
    var imageSmall: Image {
        switch self {
        case .drink:
            return Image("DiscoBall")
            
        case .food:
            return Image(systemName: "fork.knife")
            
        case .cafe:
            return Image(systemName: "CafeIcon")
        }
    }
    
    var description: String {
        switch self {
        case .drink:
            return "Drinks"
            
        case .food:
            return "Food"

        case .cafe:
            return "Cafes"
        }
    }
}

struct MapCategoryIcon: View {
    
    let style: MapIconStyle
    
    let isMap: Bool
    
    var size: CGFloat {
        isMap ? 60 : 30
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                style.startColor,
                                style.endColor
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size, height: size)
                
                Group {
                    if isMap {
                        style.imageLarge
                            .scaleEffect(0.95)
                    } else {
                        style.imageSmall
                    }
                }
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.white)
                .font(.system(size: size * 0.55, weight: .semibold))
            }
            Text(style.description)
                .font(.body(12, .bold))
                .foregroundStyle(Color.grayText.opacity(0.8))
        }
    }
}

#Preview {
    MapCategoryIcon(style: .cafe, isMap: true)
}
