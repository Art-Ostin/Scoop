//
//  TabBarItem.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import Foundation
import SwiftUI

//struct TabBarIssf: Hashable {
//    let iconName: String
//    let title: String
//    let color: Color
//}

enum TabBarItem: Hashable {
    
    case meet, invites, events, matches
    
    var image: Image {
        switch self {
        case .meet:
            return Image("AppLogoApp")
            
        case .invites:
            return Image("TabLetterGray")
            
        case .events:
            return Image("EventApp")
            
        case .matches:
            return Image("MessageApp")
        }
    }
    
    var imageBlack: Image {
        switch self {
        case .meet:
            return Image("AppLogoBlack")
            
        case .invites:
            return Image("TabLetterBlack")
            
        case .events:
            return Image("EventIcon")
            
        case .matches:
            return Image("MessageIcon")
        }
    }
}
