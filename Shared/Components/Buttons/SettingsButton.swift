//
//  SettingsButton.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

 import SwiftUI

 struct SettingsButton: View {
     let zoomNS: Namespace.ID
     let action: () -> Void
     var body: some View {
         Button(action: action) {
             Image(systemName: "gear")
                 .resizable()
                 .scaledToFit()
                 .frame(width: 20, height: 20)
                 .frame(width: 35, height: 35)
                 .glassIfAvailable(Circle())
                 .contentShape(Circle())
                 .foregroundStyle(Color.black)
                 .matchedTransitionSource(id: "settings", in: zoomNS)
         }
     }
 }
