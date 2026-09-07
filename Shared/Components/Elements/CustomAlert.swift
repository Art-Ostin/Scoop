//
//  CustomAlert.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.

import SwiftUI

struct CustomAlertCard: ViewModifier {
    
    @Binding var isPresented: Bool
    
    //The Text
    let title: String
    var emoji: String
    let message: String
    
    //The Buttons
    let cancelTitle: String
    let okTitle: String
    let offset: CGFloat
    
    //What the buttons did
    let onOK: () -> Void
    let onCancel: (() -> ())?
    
    func body(content: Content) -> some View {
        ZStack {
            //The view which I have attached the modifier to, appears below
            content
            if isPresented {
                ZStack {
                    //A black cover filling the screen and above the content beneath
                    Color.black.opacity(0.42).ignoresSafeArea()
                        .onTapGesture {
                            isPresented = false
                        }
                    
                    //The Alert Card appearing above these two elements
                    alertCard
                        .offset(y: offset) //Screens with the keyboard need the text higher
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isPresented)
    }
}

 extension CustomAlertCard {
     
     private var alertCard: some View {
         VStack(alignment: .leading, spacing: 32) {
             titleAndMessage
             buttonSection
         }
         .modifier(AlertCardBackground())
     }
     
     private var titleAndMessage: some View {
         VStack(spacing: 24) {
             Text("\(title)  \(emoji)")
                 .font(.title(24, .bold))
                 .foregroundStyle(Color.textPrimary)


             Text(message)
                 .font(.body(16, .regular))
                 .foregroundStyle(Color.textPrimary)
                 .multilineTextAlignment(.center)
                 .lineSpacing(6)
         }
         .frame(maxWidth: .infinity, alignment: .center)
     }
     
     private var buttonSection: some View {
         VStack(spacing: 16) {
             okButton
             if let dismiss = onCancel { cancelButton(dismiss)}
         }
     }
     
     private var okButton: some View {
         ScoopButton(style: .tinted(.black, shadow: nil), shape: .capsule, press: .shrink) {
             onOK()
         } label: {
             Text(okTitle)
                 .font(.body(16, .bold))
                 .foregroundStyle(Color.white)
                 .frame(height: 46)
                 .frame(maxWidth: .infinity)
         }
     }
     
     private func cancelButton(_ action: @escaping () -> Void) -> some View {
         ScoopButton(style: .tinted(.clear, shadow: nil, glass: false), shape: .capsule, press: .shrink) {
             action()
         } label: {
             Text(cancelTitle)
                 .font(.body(16, .bold))
                 .foregroundStyle(Color.black)
                 .frame(height: 46)
                 .frame(maxWidth: .infinity)
                 .capsuleStroke(lineWidth: 1, color: .textTertiary)
         }
     }
 }

struct AlertCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
            .glassEffectIfAvailable(shape: RoundedRectangle(cornerRadius: CornerRadius.alert))
            .padding(.horizontal, 32)
            .shadow(.floating)
    }
}

extension View {
    func customAlertCard(
        isPresented: Binding<Bool>,
        
        title: String,
        emoji: String = "🦥",
        message: String,
        
        cancelTitle: String = "Cancel",
        okTitle: String = "OK",
        
        offset: CGFloat = 0,
        
        onOK: @escaping () -> Void,
        onCancel: (() -> ())? = nil
    ) -> some View {
        modifier(
            CustomAlertCard(
                isPresented: isPresented,
                title: title,
                emoji: emoji,
                message: message,
                cancelTitle: cancelTitle,
                okTitle: okTitle,
                offset: offset,
                onOK: onOK,
                onCancel: onCancel
            )
        )
    }
}
