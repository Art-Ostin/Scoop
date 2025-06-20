//
//  GoingOutView.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/06/2025.
//

import SwiftUI

struct GoingOutView: View {
    
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 148), spacing: 16)]
    
    @State private var goingOut: [String] = ["🌞 Everyday", "🍻5/6 a week", "🎟 3/4 a week", "🎶 twice a week", "🎊 Once a week", "🌙 Sometimes", "📝Rarely"]
    
    var selectedIndex: Int? = nil
    
    
    
    var body: some View {
            
            
            
        }
        
        
    }


#Preview {
    GoingOutView()
}
