//
//  PopUpView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct PopUpView: View {
    
    var profile: UserProfile
    
    @State var showProfile: UserProfile? = nil
    
    @State var image: UIImage? = nil
    
    var body: some View {
        
        VStack(spacing: 23) {
            
//            if let string = profile.imagePathURL?.first, let url = URL(string: string)  {
//                imageContainer(url: url, size: 140, shadow: 0)
//            }
            
            Text("\(String(describing: profile.name))'s down to meet")
                .font(.title(24))
            
            Text("You have 24 hours to respond")
                .font(.body(16, .bold))
            
            ActionButton(text: "View Invite") {
                showProfile = profile
            }
        }
        .padding([.bottom, .horizontal], 32)
        .padding(.top, 24)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
        )
    }
}


//#Preview {
//    PopUpView(profile: )
//}
