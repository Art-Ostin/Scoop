//
//  ImageOverlayTester.swift
//  Scoop
//
//  Created by Art Ostin on 15/01/2026.
//

import SwiftUI

struct ImageOverlayTester: View {
    
 
    
    var body: some View {
        
        let monkey = Image("Monkey")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
        
        VStack {
            monkey

            // Blurred copy, revealed only inside the rounded-rect mask
            monkey
                .blur(radius: 4) // your Gaussian-ish blur
                .overlay {
                    Text("")
                }
                .mask(
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 50, height: 50)
                        .offset(x: 0, y: 0) // move the blurred region
                )
        }
    }
}

#Preview {
    ImageOverlayTester()
}
