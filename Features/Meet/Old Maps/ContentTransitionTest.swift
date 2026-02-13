//
//  ContentTransitionTest.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

struct ContentTransitionTest: View {
    @Namespace var ZoomNS
    
    @State var showScreen1 = true
    
    var body: some View {
        
        if showScreen1 {
            
            NavigationLink {
                
            } label: {
                Text("show Screen 1")
                    .background(
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 300, height: 300)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 6)
                    )
            }

            Button {
                
                
                showScreen1.toggle()
            } label: {
                Text("show Screen 1")
                    .background(
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 300, height: 300)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 6)
                    )
            }
        } else {
            Button {
                showScreen1.toggle()
            } label : {
                Text("screen 1")
                    .background(
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 30, height: 300)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 6)
                    )
            }
        }
        

        
        
        
    }
    private var screen1: some View {
        Rectangle()
            .frame(width: 300, height: 300)
    }
    
    private var screen2: some View {
        Rectangle()
            .frame(width: 80, height: 80)
    }
}

#Preview {
    ContentTransitionTest()
}
