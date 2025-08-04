//
//  PopUpView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct PopUpView: View {
    
    var profile: UserProfile
    
    
    var body: some View {

        VStack(spacing: 23) {
            
            if let string = profile.imagePathURL?.first, let url = URL(string: string)  {
                imageContainer(url: url, size: 140, shadow: 0)
            }
            
            Text("\(String(describing: profile.name))'s down to meet")
            
            
                        
        }
        .padding([.bottom, .horizontal], 32)
        .padding(.top, 24)
    }
}

//#Preview {
//    PopUpView()
//}
