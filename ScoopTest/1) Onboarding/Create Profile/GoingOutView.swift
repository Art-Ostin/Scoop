//
//  GoingOutView.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/06/2025.
//

import SwiftUI

struct GoingOutView: View {
    
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 148), spacing: 16)]
    
    @State private var goingOut: [String] = ["🌞  Everyday", "🍻  5/6 a week", "🎟  3/4 a week", "🎶  twice a week", "🎊  Once a week", "🌙  Sometimes"]
    
    var selectedIndex: Int? = nil
    
    var body: some View {
        
        VStack{
            SignUpTitle(text: "I Go Out", count: 5)
                .padding(.top, 32)
            
//            OptionView(options: goingOut, width: 163, HSpacing: 23, VSpacing: 28, isFilled: false)
//                .padding(.top, 60)
        }
        
        }
    }


#Preview {
    GoingOutView()
        .padding(32)
}
