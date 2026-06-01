//
//  ButtonTestView.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.

import SwiftUI

struct ButtonTestView: View {
    let dismissType: DismissType = .back
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 32) {
                infoButtonTest
                
                DismissButton(type: .cross)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 48 + 36)
        }
    }
}

extension ButtonTestView {
        
    private var infoButtonTest: some View {
        Button {
            
        } label: {
                Image(systemName: "info.circle")
                    .font(.body(18, .medium))
                    .padding(8)//Keeps size of pre Ios 26 and Ios 26 buttons the same
                    .background(Circle().fill(.ultraThinMaterial).brightness(0.07))
                    .foregroundStyle(Color.black)
            }
            .customButtonGrowAndShadow(.customGlassShadow)
        }
    }


 struct NewDismissButton: View {
     let dismiss: () -> ()
     var body: some View {
         Button {
             dismiss()
         } label : {
             Image(systemName: "xmark")
                 .font(.body(18, .bold))
                 .padding(12)
                 .glassIfAvailable(Circle())
                 .contentShape(Circle())
                 .foregroundStyle(Color.black)
                 .padding(.horizontal)
         }
     }
 }
 
 extension View {
     @ViewBuilder
     func glassIfAvailable<S: InsettableShape>(_ shape: S = Capsule(), isClear: Bool = true, thinMaterial: Bool = false) -> some View {
         if #available(iOS 26.0, *) {
             self
                 .glassEffect(isClear ? .clear : .regular, in: shape)
         } else {
             self
                 .background {shape.fill(Color.appCanvas)}
                 .overlay {shape.strokeBorder(Color.grayBackground, lineWidth: 0.4)}
                 .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                 .background(Capsule().fill(thinMaterial ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear)))
         }
     }
 }
