//
//  PopUpView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct PopUpView: View {
    
    var invitee: UserProfile?
    
    
    var body: some View {

        VStack(spacing: 23) {
            
            
            imageContainer(url: <#T##URL#>, size: <#T##CGFloat#>, vm: $invitee)
            
            
        }
        .padding([.bottom, .horizontal], 32)
        .padding(.top, 24)


    }
}

#Preview {
    PopUpView()
}
