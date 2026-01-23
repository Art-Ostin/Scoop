//
//  LockedScreen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct LockedScreen: View {
    
    @State var showWhyBlocked: Bool = false
    
    var body: some View {
        VStack(spacing: 72) {
            VStack(spacing: 24) {
                Text("Your Account is Blocked")
                    .font(.custom("SFProRounded-Bold", size: 32))
                
                Text("arthur.ostin@mail.mcgill.ca")
                    .font(.body(20, .medium))
                
                
                Image("Monkey")
                
            }
            .padding(.top, 96)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
            .overlay (alignment: .topTrailing){
                TabInfoButton(showScreen: $showWhyBlocked)
            }
            .sheet(isPresented: $showWhyBlocked) {
                
            }
        }
    }
}

#Preview {
    LockedScreen(showWhyBlocked: true)
}
