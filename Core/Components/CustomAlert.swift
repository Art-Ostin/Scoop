//
//  CustomAlert.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.
//

import SwiftUI

struct CustomAlertCard: View {
    let title: String
    let message: String
    let showTwoButtons: Bool
    let onCancel: () -> Void
    let onOK: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            
            titleAndMessage
            
            buttonSection
        }
        .padding(24)
        .frame(width: 320)
        .glassIfAvailable(RoundedRectangle(cornerRadius: 24), isClear: false)
        .defaultShadow()
        .frame(maxWidth: .infinity)
    }
}

extension CustomAlertCard {
    
    private var titleAndMessage: some View {
        VStack(alignment: showTwoButtons ? .leading : .center, spacing: 24) {
            Text("\(title)  🦥")
                .font(.body(20, .bold))
            
            Text(message)
                .font(.body(16))
                .foregroundStyle(Color.black.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: showTwoButtons ? .leading : .center)
    }
    
    private var buttonSection: some View {
        HStack {
            if showTwoButtons {
                customButton(isCancel: true)
                Spacer()
            }
            customButton(isCancel: false)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func customButton(isCancel: Bool) -> some View {
        Button {
            if isCancel {
                onCancel()
            } else {
                onOK()
            }
        } label:  {
            Text(isCancel ? "Cancel" : "OK")
                .font(.body(17, .bold))
                .foregroundStyle(isCancel ? .black : .white)
                .padding(.vertical, 14)
                .frame(width: 100)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(isCancel ? Color.background : Color.accent)
                )
                .stroke(20, lineWidth: isCancel ? 1 : 0, color: .grayText)
                .frame(maxWidth: .infinity,  alignment: showTwoButtons ? (isCancel ? .leading : .trailing) : .center)
        }
    }
}

struct CustomAlertModifier: ViewModifier {
    
    @Binding var isPresented: Bool
    
    let title: String
    let message: String
    let showTwoButtons: Bool
    let onOK: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // Optional: tap outside to dismiss
                                isPresented = false
                            }
                        
                        CustomAlertCard(
                            title: title,
                            message: message,
                            showTwoButtons: showTwoButtons,
                            onCancel: { isPresented = false },
                            onOK: {
                                onOK()
                                isPresented = false
                            }
                        )
                    }
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
            .allowsHitTesting(!isPresented ? true : true)
            .animation(.easeInOut(duration: 0.18), value: isPresented)
    }
}

extension View {
    func customAlert(isPresented: Binding<Bool>, title: String = "Error", message: String, showTwoButtons: Bool, onOK: @escaping () -> Void) -> some View {
        modifier(CustomAlertModifier(isPresented: isPresented, title: title, message: message, showTwoButtons: showTwoButtons, onOK: onOK))
    }
}

/*
 .background(
     RoundedRectangle(cornerRadius: 24)
         .foregroundStyle(Color.background)
         .defaultShadow()
 )
 */
