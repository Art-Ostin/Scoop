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
    let isConfirmInvite: Bool

    let onCancel: () -> Void
    let onOK: () -> Void
    let cancelTitle: String
    let okTitle: String
    let emoji: String
    
    var isDanger: Bool {
        cancelTitle == "Back"
    }
    

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
        .lineSpacing(8)
    }
}

extension CustomAlertCard {
    
    private var titleAndMessage: some View {
        VStack(alignment: showTwoButtons ? .leading : .center, spacing: isConfirmInvite ? 16 : 24) {
            Text("\(title)  \(emoji)")
                .font(.body(20, .bold))
            
            Text(message)
                .font(.body(16))
                .foregroundStyle(Color.black.opacity(0.8))
                .multilineTextAlignment(showTwoButtons ? .leading : .center)
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
            Text(isCancel ? cancelTitle : okTitle)
                .font(.body(17, .bold))
                .foregroundStyle(isCancel ? (isDanger ? Color.white : Color.black) : (isDanger ? Color.black : Color.white))
                .padding(.vertical, 14)
                .frame(width: isConfirmInvite ? 125 : 100)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(isCancel ? (isDanger ? Color.accent : Color.background) : (isDanger ? Color.background : Color.accent) )
                )
                .stroke(20, lineWidth: isCancel ? (isDanger ? 0 : 1) : (isDanger ? 1 : 0), color: .grayText)
                .frame(maxWidth: .infinity,  alignment: showTwoButtons ? (isCancel ? .leading : .trailing) : .center)
        }
    }
}

struct CustomAlertModifier: ViewModifier {
    
    @Binding var isPresented: Bool
    
    let title: String
    let message: String
    let showTwoButtons: Bool
    let cancelTitle:String
    let okTitle: String
    let emoji: String
    
    let isConfirmInvite: Bool

    let onOK: () -> Void
    
    
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(isConfirmInvite ? 0.3 : 0.42)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // Optional: tap outside to dismiss
                                isPresented = false
                            }
                        
                        CustomAlertCard(
                            title: title,
                            message: message,
                            showTwoButtons: showTwoButtons,
                            isConfirmInvite: isConfirmInvite,
                            onCancel: { isPresented = false },
                            onOK: {
                                onOK()
                                isPresented = false
                            }, cancelTitle: cancelTitle, okTitle: okTitle, emoji: emoji
                        )
                        .offset(y: isConfirmInvite ? 48 : 0)
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
    func customAlert(isPresented: Binding<Bool>, title: String = "Error", cancelTitle: String = "Cancel", okTitle: String = "OK", emoji: String = "🦥", message: String, showTwoButtons: Bool, isConfirmInvite: Bool = false, onOK: @escaping () -> Void) -> some View {
        modifier(CustomAlertModifier(isPresented: isPresented, title: title, message: message, showTwoButtons: showTwoButtons, cancelTitle: cancelTitle, okTitle: okTitle, emoji: emoji, isConfirmInvite: isConfirmInvite, onOK: onOK))
    }
}
