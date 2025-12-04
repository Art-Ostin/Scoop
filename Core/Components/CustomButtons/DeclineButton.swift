//
//  DeclineButton.swift
//  Scoop
//
//  Created by Art Ostin on 02/11/2025.
//

import SwiftUI

struct DeclineButton: View {
    let image: String = "DeclineIcon"
    let onTap: () -> ()
    
    var body: some View {
                Image(image)
                .frame(width: 45, height: 45)
                .glassIfAvailable()
                .stroke(100, lineWidth: 1, color: Color(red: 0.93, green: 0.93, blue: 0.93))
                .contentShape(Rectangle())
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 100)
                .onTapGesture {onTap()}
            
        }
}

/*
 struct TabButton: View {
     let image: Image
     @Binding var isPresented: Bool
     let size: CGFloat
     var isSettings: Bool { size == 20 }
     let padding: CGFloat
     
     init(image: Image, isPresented: Binding<Bool>, size: CGFloat = 17, padding: CGFloat = 6) {
         self.image = image
         _isPresented = isPresented
         self.size = size
         self.padding = padding
     }
     
     var body: some View {
         Group {
             if #available(iOS 26.0, *) {
                 button
                     .glassEffect()
             } else {
                 button
                     .background( Circle().fill(Color.background) )
                     .overlay( Circle().strokeBorder(Color.grayBackground, lineWidth: 0.4) )
                     .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
             }
         }
         .frame(maxWidth: .infinity, alignment: isSettings ? .leading : .trailing)
         .padding(.horizontal, isSettings ? 0 : 24)
         .padding(.top, isSettings ? 0 : 60)
     }
 }

 extension TabButton {
     private var button: some View {
         image
             .font(.body(size))
             .padding(padding)
             .foregroundStyle(.black)
             .onTapGesture {
                 isPresented = true
             }
     }
 }
 
 
 
 
 Group {
     if #available(iOS 26.0, *) {
         image
             .padding(padding)
             .onTapGesture {
                 onTap()
             }
             .glassEffect()
     } else {
         image
         .frame(width: 45, height: 45)
         .glassIfAvailable()
         .stroke(100, lineWidth: 1, color: Color(red: 0.93, green: 0.93, blue: 0.93))
         .contentShape(Rectangle())
         .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 100)
         .onTapGesture {onTap()}
     }
 }

 */
