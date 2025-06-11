//
//  ParentContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//

import SwiftUI

struct ParentContainer: View {
    @State var selection: Int = 0
    
    var body: some View {
        TabView (selection: $selection) {
            
            Tab("", image: "letterIcon", value: 0) {
                MeetContainerView()
            }
            
            Tab("", image: "LogoIcon", value: 1) {
                createProfilePage(title: "Events", Screenimage: "Monkey", description: "If you match with someone and are meeting up, details will appear here.", showProfile: false)
            }
            
            Tab("", image: "MessageIcon", value: 2) {
                createProfilePage(title: "Matches", Screenimage: "DancingCats", description: "You can see all previous meet ups here", showProfile: true)
            }
        }
    }
}
    #Preview {
        ParentContainer()
            .environment(ScoopViewModel())
    }


