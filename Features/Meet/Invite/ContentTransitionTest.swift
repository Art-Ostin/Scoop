//
//  ContentTransitionTest.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

struct ContentTransitionTest: View {
    
    @Namespace var zoomNS
    
    @State var showScreen1 = true
    
    var body: some View {
        NavigationStack {
            if showScreen1 {
                NavigationLink {
                    Screen2Test()
                        .navigationTransition(.zoom(sourceID: "testImage", in: zoomNS))
                } label: {
                    Text("show Screen 2")
                        .background(
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 300, height: 300)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 6)
                        )
                        .matchedTransitionSource(id: "testImage", in: zoomNS)
                }
            }
        }
    }
}

#Preview {
    ContentTransitionTest()
}

struct Screen2Test: View {
    
    @Environment(\.dismiss) private var dismiss
    
//    
    var body: some View {
        
        ZStack {
            CustomScreenCover {}
            
            
                Rectangle()
                .frame(height: 450)
                .frame(width: 365)
                .background (
                    ZStack { //Background done like this to fix bugs when popping up
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.background)
                            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(Color.grayBackground, lineWidth: 0.5)
                    }
                )

            
        }
        
        
        Button {
            dismiss
        } label: {
            Text("Go back ")
            .background(
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 40, height: 50)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 6)
            )
        }

        
        
        Button("Back") {
            dismiss()
        }
    }
}

