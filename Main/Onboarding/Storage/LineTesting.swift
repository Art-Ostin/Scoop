//
//  LineTesting.swift
//  Scoop
//
//  Created by Art Ostin on 20/10/2025.
//

import SwiftUI
import SwiftUIFlowLayout


struct TabViewSpacing: View {
    
    struct Item: Identifiable {
        let id = UUID()
        let image: String
        let label: String
    }

    let items: [Item] = [
        
        .init(image: "WeedIcon", label: "Sometimes"),
        .init(image: "DrugsIcon", label: "Sometimes"),
        .init(image: "CigaretteIcon", label: "Delete"),
        .init(image: "AlcoholIcon", label: "Always"),
        .init(image: "GenderIcon", label: "Male"),
        .init(image: "Languages", label: "French")
        
    ]
    
    var body: some View {
        
        FlowLayout(mode: .vstack, items: items, itemSpacing: 36) { name in
            Image(name.image).resizable().aspectRatio(contentMode: .fit).frame(width: 19, height: 19)
        }
        .padding(.horizontal, 36)

    }
}

#Preview {
    TabViewSpacing()
}


#Preview {
    TabViewSpacing()
}
