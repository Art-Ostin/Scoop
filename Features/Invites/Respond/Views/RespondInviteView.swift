//
//  RespondContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct RespondInviteView: View {
    
    @Binding var showPopup: Bool
    
    let images: [UIImage]
    
    
    
    
    @State var vm: RespondViewModel
    
    var isNewInvite { vm.responseType == .}
    
    
    
    
    var body: some View {

        
        ZStack {
            Rectangle() //Full Bleed
                .fill(Color.white)
                .ignoresSafeArea()
            
            
            VStack(spacing: 0) {
                Text("Respond")
                inviteCard
                backButton
            }
        }
    }
}

extension RespondInviteView {
    
    
    private var inviteCard: some View {
        VStack(spacing: 0) {
            imageCarousel
            inviteDetailsSection
        }
        
    }
    
    
    private var imageCarousel: some View {
        
    }
    
    private var inviteDetailsSection: some View {
        
    }
    
    
    private var backButton: some View {
        BottomBackButton(showInvite:  $showPopup)
    }
}
