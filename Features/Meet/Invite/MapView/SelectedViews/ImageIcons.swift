//
//  ImageIcons.swift
//  Scoop
//
//  Created by Art Ostin on 03/02/2026.
//

import SwiftUI
import MapKit


extension MKPointOfInterestCategory {

        var image: Image {
            // 10%: custom (non-SF) images from your asset catalog
            if let asset = assetOverrideName {
                return Image(asset)
            }

            // 90%: SF Symbols (with a safe fallback if the symbol doesn’t exist on the OS)
            return sfSymbol(sfSymbolName, fallback: "mappin")
        }

        // Put ONLY the categories you want to use custom app images for (your “10%”)
        private var assetOverrideName: String? {
            switch self {
            case .winery:       return "poi_winery"        // example asset
            case .nightlife:    return "DiscoBall"
            default:            return nil
            }
        }

        // SF Symbol mapping for everything else
        private var sfSymbolName: String {
            switch self {
            case .airport:          return "airplane"
            case .amusementPark:    return "sparkles"
            case .aquarium:         return "fish"
            case .atm:              return "banknote"
            case .bakery:           return "birthday.cake"
            case .bank:             return "building.columns"
            case .beach:            return "sun.max"
            case .brewery:          return "mug"
            case .cafe:             return "cup.and.saucer"
            case .campground:       return "tent"
            case .carRental:        return "car"
            case .evCharger:        return "bolt.car"
            case .fireStation:      return "flame"
            case .fitnessCenter:    return "dumbbell"
            case .foodMarket:       return "cart"
            case .gasStation:       return "fuelpump"
            case .hospital:         return "cross.case"
            case .hotel:            return "bed.double"
            case .laundry:          return "tshirt"
            case .library:          return "books.vertical"
            case .marina:           return "sailboat"
            case .movieTheater:     return "film"
            case .museum:           return "building.columns"
            case .nationalPark:     return "leaf"
            case .park:             return "tree"
            case .parking:          return "parkingsign"
            case .pharmacy:         return "pills"
            case .police:           return "shield"
            case .postOffice:       return "envelope"
            case .publicTransport:  return "bus"
            case .restaurant:       return "fork.knife"          // used only if you DON’T override it above
            case .restroom:         return "toilet"
            case .school:           return "book"
            case .stadium:          return "sportscourt"
            case .store:            return "bag"
            case .theater:          return "theatermasks"
            case .university:       return "graduationcap"
            case .winery:           return "wineglass"           // used only if you DON’T override it above
            case .zoo:              return "pawprint"

            case .animalService:    return "pawprint"
            case .automotiveRepair: return "wrench.and.screwdriver"
            case .baseball:         return "figure.baseball"
            case .basketball:       return "figure.basketball"
            case .beauty:           return "scissors"
            case .bowling:          return "figure.bowling"
            case .castle:           return "crown"
            case .conventionCenter: return "person.3"
            case .distillery:       return "drop"
            case .fairground:       return "party.popper"
            case .fishing:          return "figure.fishing"
            case .fortress:         return "shield"
            case .golf:             return "figure.golf"
            case .goKart:           return "flag.checkered"
            case .hiking:           return "figure.hiking"
            case .kayaking:         return "figure.rowing"
            case .landmark:         return "mappin.and.ellipse"
            case .mailbox:          return "mailbox"
            case .miniGolf:         return "flag"
            case .musicVenue:       return "music.note"
            case .nationalMonument: return "building.columns"
            case .planetarium:      return "telescope"
            case .rockClimbing:     return "figure.climbing"
            case .rvPark:           return "house.and.car"
            case .skatePark:        return "figure.skateboarding"
            case .skating:          return "figure.ice.skating"
            case .skiing:           return "figure.skiing.downhill"
            case .soccer:           return "figure.outdoor.soccer"
            case .spa:              return "leaf"
            case .surfing:          return "figure.surfing"
            case .swimming:         return "figure.pool.swim"
            case .tennis:           return "tennis.racket"
            case .volleyball:       return "figure.volleyball"

            default:
                return "mappin"
            }
        }

        private func sfSymbol(_ name: String, fallback: String) -> Image {
            if UIImage(systemName: name) != nil { return Image(systemName: name) }
            return Image(systemName: fallback)
        }
    
    
    var startColor: Color {
        switch self {
            //Pink
        case .nightlife:
            return Color(red: 1, green: 0.51, blue: 0.75)

            //Green
        case .park:
            return  Color(red: 0.529, green: 0.851, blue: 0.486)
            
            //Purple
        case .atm:
            return  Color(red: 0.522, green: 0.510, blue: 0.882)
            
            //Orange
        case .brewery, .restaurant:
            return  Color(red: 0.99, green: 0.69, blue: 0.28)
            
            //Red
        case .airport:
            return Color(red: 245/255, green: 106/255, blue: 135/255)

            //Blue
        case .bank:
            return  Color(red:  76/255, green: 141/255, blue: 242/255)
            
            //Brown
        case .school, .university:
            return  Color(red: 166/255, green: 122/255, blue:  93/255)
            
            //Purple
        case .baseball:
            return Color(red: 166/255, green: 111/255, blue: 232/255)

        default:
            return Color(red: 245/255, green: 106/255, blue: 135/255)
        }
    }
    
    var endColor: Color {
        switch self {
            //Pink
        case .nightlife:
            return Color(red: 0.86, green: 0.11, blue: 0.53)

            //Green
        case .park:
            return Color(red: 0.310, green: 0.639, blue: 0.318)
            
            //Purple
        case .atm:
            return   Color(red: 0.376, green: 0.361, blue: 0.729)
            
            //Orange
        case .brewery, .restaurant:
            return  Color(red: 0.96, green: 0.44, blue: 0.18)
            
            //Red
        case .airport:
            return  Color(red: 212/255, green:  51/255, blue:  82/255)

            //Blue
        case .bank:
            return  Color(red:  47/255, green: 106/255, blue: 228/255)
            
            //Brown
        case .school, .university:
            return  Color(red: 108/255, green:  69/255, blue:  51/255)
            
            //Purple
        case .baseball:
            return  Color(red: 123/255, green:  67/255, blue: 199/255)

        default:
            return Color(red: 245/255, green: 106/255, blue: 135/255)
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







