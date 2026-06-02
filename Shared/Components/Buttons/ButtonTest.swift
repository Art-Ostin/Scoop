//
//  ButtonTest.swift
//  Scoop Test
//
//  Created by Art Ostin on 02/06/2026.
//

import SwiftUI

struct ButtonTest: View {
    var body: some View {
        VStack(spacing: 72) {
            if #available(iOS 26.0, *) {
                ScoopButton(shape: Circle(), size: .large, action: {print("Hello 1")}) {
                    Image(systemName: "xmark")
                }
                
                ScoopButton(shape: Circle(), size: .medium, weight: .semibold) {
                    print("Hello World")
                } label: {
                    Image(systemName: "gear")
                        .foregroundStyle(.black)
                }
                
                ScoopButton(style: .tinted(.accent, shadow: .high), shape: .rect(cornerRadius: 16)) {
                    print("Yes")
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 72, height: 44)
                }
                
                
            } else {
                
            }
        }
    }
}


 


/*
 
 Button {
     print("Helloo World IOS 18")
 } label: {
     Image(systemName: "xmark")
         .frame(width: 40, height: 40)
         .background(Circle().fill(.ultraThinMaterial).brightness(0.06))
         .expandHitArea()
         .growPress(shadow: .customGlassShadow)
 }
 .buttonStyle(.plain)

 Image(systemName: "xmark")
     .frame(width: 40, height: 40)
     .glassEffect(.clear.interactive(), in: .circle)
     .contentShape(Circle())
     .onTapGesture {
         print("Ios 26")
     }
 */
