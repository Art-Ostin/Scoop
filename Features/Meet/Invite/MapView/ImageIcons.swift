//
//  ImageIcons.swift
//  Scoop
//
//  Created by Art Ostin on 03/02/2026.
//

import SwiftUI
import MapKit


extension MKPointOfInterestCategory {

    var image: String {
        switch self {
        case .restaurant:
            return "fork.knife"
        default:
            return "wineglass"
        }
    }
    
    var startColor: Color {
        switch self {
            case .restaurant:
                return Color(red: 1.00, green: 0.84, blue: 0.20)
            default:
                return Color(red: 1.00, green: 0.84, blue: 0.20)
        }
    }
    
    var endColor: Color {
        switch self {
        case .restaurant:
            return Color(red: 0.96, green: 0.64, blue: 0.10)
            
        default:
            return Color(red: 0.96, green: 0.64, blue: 0.10)
        }
    }
    
}


enum MapIcons {
    
    case restaurant, bar, nightClub
    
    
    var image: String {
        switch self {
        case .restaurant:
            return ""
        case .bar:
            return ""
        case .nightClub:
            return ""
        }
    }
    
    
    var startColor: Color {
        switch self {
        case .restaurant:
           return Color(red: 1.00, green: 0.84, blue: 0.20)
            
        case .bar:
            return Color(red: 1.00, green: 0.84, blue: 0.20)

        case .nightClub:
            return Color(red: 1.00, green: 0.84, blue: 0.20)

            
        }
    }
    
    var endColor: Color {
        switch self {
        case .restaurant:
            Color(red: 0.96, green: 0.64, blue: 0.10)

        case .bar:
            Color(red: 0.96, green: 0.64, blue: 0.10)

        case .nightClub:
            Color(red: 0.96, green: 0.64, blue: 0.10)
        }
    }
}







