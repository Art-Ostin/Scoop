//
//  MenuTester.swift
//  Scoop Test
//
//  Created by Art Ostin on 12/06/2026.
//

import SwiftUI

struct MenuTester: View {
    @Namespace private var glass
    @State private var expanded = false

    
    var body: some View {
        
        
        

        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                if expanded {
                    VStack {
                        Text("This photo will be deleted...")
                        Button("Delete Photo", role: .destructive) {}
                    }
                    .padding(24)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
                    .glassEffectID("delete", in: glass)
                    .glassEffectTransition(.matchedGeometry)
                } else {
                    Button {
                        withAnimation(.smooth(duration: 0.35)) {
                            expanded = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 56, height: 56)
                    }
                    .glassEffect(.regular.interactive(), in: Circle())
                    .glassEffectID("delete", in: glass)
                    .glassEffectTransition(.matchedGeometry)
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        
        VStack(spacing: 96) {
            TypeCustomMenu {
                VStack {
                    Text("Hello World")
                    Text("Hello World")
                    Text("Hello World")
                }
                .padding()
                .frame(width: 250, height: 200)
            } label: {
                customButton
            }
            
            Menu {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            } label : {
                customButton
            }
        }
    }
    
    private var customButton: some View {
        Text("Open Button")
            .font(.body(14, .bold))
            .foregroundStyle(Color.white)
            .padding()
            .background(Color.blue, in: .rect(cornerRadius: 16))
    }
}

