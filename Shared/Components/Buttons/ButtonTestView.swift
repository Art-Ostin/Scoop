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
                twentySixVersion

                eighteenVersion
                
                DismissButton(.cross)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//            .offset(y: -56.5)
            .padding(.leading, 48 + 36)
            .toolbar {DismissToolbarItem(.cross)}
        }
    }
}

extension ButtonTestView {
    @ViewBuilder
    private var twentySixVersion: some View {
        if #available(iOS 26.0, *) {
            Button {

            } label: {
                buttonLabel
                    .padding(6)
            }
            .foregroundStyle(Color.black)
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(.clear)
        }
    }

    private var eighteenVersion: some View {
        Button {

        } label: {
            buttonLabel
                .padding(15)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .brightness(0.06)
                )
        }
        .customButtonGrowAndShadow(.customGlassShadow)
    }
    
    private var buttonLabel: some View {
        Image(systemName: "chevron.left")
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(Color.black)
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

/*
 .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
 .shadow(color: .black.opacity(0.01), radius: 24, x: 0, y: 9)

 */
