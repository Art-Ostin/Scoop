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
                startColor: Color(red: 0.99, green: 0.87, blue: 0),
                endColor:   Color(red: 0.98, green: 0.53, blue: 0),
                mainColor:  Color(red: 1, green: 0.28, blue: 0),
                image: Image("ForkSpoon"),
                description: "Food"
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
                description: "Bars"
            )
            
        //Orange DONE
        case .pub:
            return .init(
                startColor: Color(red: 0.99, green: 0.69, blue: 0.28),
                endColor:   Color(red: 0.96, green: 0.44, blue: 0.18),
                mainColor: Color(red: 1, green: 0.28, blue: 0),
                image: Image("BeerIcon"),
                description: "Pubs"
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
                startColor: Color(red: 0.17, green: 0.89, blue: 0.39),
                endColor:    Color(red: 0, green: 0.61, blue: 0.21),
                mainColor:  Color(red: 0.89, green: 0.09, blue: 0.55),
                image: Image("TreeIcon"),
                description: "Parks"
            )


        //Teal
        case .activity:
            return .init(
                startColor: Color(red: 0, green: 0.89, blue: 1),
                endColor:   Color(red: 0, green: 0.62, blue: 0.72),
                mainColor:  Color(red: 0.89, green: 0.09, blue: 0.55),
                image: Image(systemName: "figure.climbing"),
                description: "Activities"
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

