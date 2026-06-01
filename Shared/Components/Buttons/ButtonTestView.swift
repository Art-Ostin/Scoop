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
            VStack(spacing: 72) {
                twentySixVersion

                eighteenVersion
            }
            .toolbar {DismissToolbarItem(.back)}
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
                .padding(7)
                .background(Circle().fill(.ultraThinMaterial).brightness(0.065))
                .overlay(Circle().strokeBorder(Color.grayBackground, lineWidth: 0.4))
        }
        .customButtonPressAndShadow(.ultraLow)
    }
    
    
    private var buttonLabel: some View {
        Image(systemName: dismissType == .cross ? "xmark" : "chevron.left")
            .font(.system(size: dismissType == .cross ? 12 : 14, weight: .heavy))
            .foregroundStyle(Color.black)
    }
}

/*
 
 struct DismissButton: View {
      
     @Environment(\.dismiss) private var dismiss
     
     let dismissType: DismissType

     var body: some View {
         if #available(iOS 26.0, *) {
             Button {
                 dismiss()
             } label: {
                 buttonLabel
             }
             .foregroundStyle(Color.black)
             .buttonStyle(.glassProminent)
             .buttonBorderShape(.circle)
             .tint(.clear)
         } else {
             Button {
                 dismiss()
             } label: {
                 buttonLabel
                     .padding(7)
                     .background(Circle().fill(.ultraThinMaterial).brightness(0.065))
                     .overlay(Circle().strokeBorder(Color.grayBackground, lineWidth: 0.4))
             }
             .customButtonPressAndShadow(.ultraLow)
         }
     }
     
     private var buttonLabel: some View {
         Image(systemName: dismissType == .cross ? "xmark" : "chevron.left")
             .font(.system(size: dismissType == .cross ? 12 : 14, weight: .heavy))
             .foregroundStyle(Color.black)
     }
 }
 */




/*
 @ViewBuilder
 private var twentySixVersion: some View {
     if #available(iOS 26.0, *) {
         Button {
         } label: {
             Image(systemName: "info.circle")
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
         Image(systemName: "info.circle")          // match the 26 label
             .padding(7)                             // breathing room glass adds for you
             .background(Circle().fill(.ultraThinMaterial).brightness(0.065))   // translucent, like clear-tint glass
             .overlay(Circle().strokeBorder(Color.grayBackground, lineWidth: 0.4))
     }
     .customButtonPressAndShadow(.ultraLow)              // single press response
 }


 */
