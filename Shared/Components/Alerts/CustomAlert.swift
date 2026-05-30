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
                        .foregroundStyle(isCancel ? (isDanger ? Color.accent : Color.appCanvas) : (isDanger ? Color.appCanvas : Color.accent) )
                )
                .stroke(20, lineWidth: isCancel ? (isDanger ? 0 : 1) : (isDanger ? 1 : 0), color: Color.grayText)
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
    
    // Animation used when the alert is dismissed (cancel/OK). Defaults to the show speed.
    var hideAnimation: Animation = .easeInOut(duration: 0.18)

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                ZStack {
                    Color.black.opacity(isConfirmInvite ? 0.3 : 0.42)
                        .onTapGesture {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(isPresented ? .easeInOut(duration: 0.18) : hideAnimation, value: isPresented)
    }
}

// MARK: - Item-based variant (driven by an optional String)

struct CustomAlertItemModifier: ViewModifier {

    @Binding var item: String?

    let title: String
    let message: String
    let showTwoButtons: Bool
    let cancelTitle: String
    let okTitle: String
    let emoji: String

    let isConfirmInvite: Bool

    let onOK: (String) -> Void


    func body(content: Content) -> some View {
        ZStack {
            content
            if let value = item {
                ZStack {
                    Color.black.opacity(isConfirmInvite ? 0.3 : 0.42)
                        .onTapGesture {
                            item = nil
                        }

                    CustomAlertCard(
                        title: title,
                        message: message,
                        showTwoButtons: showTwoButtons,
                        isConfirmInvite: isConfirmInvite,
                        onCancel: { item = nil },
                        onOK: {
                            onOK(value)
                            item = nil
                        }, cancelTitle: cancelTitle, okTitle: okTitle, emoji: emoji
                    )
                    .offset(y: isConfirmInvite ? 48 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: item)
    }
}

extension View {
    
    func customAlert(
        isPresented: Binding<Bool>,
        title: String = "Error",
        message: String,
        emoji: String = "🦥",
        cancelTitle: String = "Cancel",
        okTitle: String = "OK",
        showTwoButtons: Bool,
        isConfirmInvite: Bool = false,
        onOK: @escaping () -> Void
    ) -> some View {
        modifier(
            CustomAlertModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                showTwoButtons: showTwoButtons,
                cancelTitle: cancelTitle,
                okTitle: okTitle,
                emoji: emoji,
                isConfirmInvite: isConfirmInvite,
                onOK: onOK
            )
        )
    }
        
    func respondCustomAlert(isPresented: Binding<Bool>, type: RespondPopupInfo, hideAnimation: Animation = .easeInOut(duration: 0.18), onOK: @escaping () -> Void) -> some View {
        modifier(CustomAlertModifier(
            isPresented: isPresented,
            title: type.title,
            message: type.message(),
            showTwoButtons: true,
            cancelTitle: type.cancel,
            okTitle: type.understand,
            emoji: "🦥",
            isConfirmInvite: true, onOK: onOK,
            hideAnimation: hideAnimation)
        )
    }
    
    func customAlert(
        item: Binding<String?>,
        title: String = "Error",
        cancelTitle: String = "Cancel",
        okTitle: String = "OK",
        emoji: String = "🦥",
        message: String,
        showTwoButtons: Bool,
        isConfirmInvite: Bool = false,
        onOK: @escaping (String) -> Void
    ) -> some View {
        modifier(CustomAlertItemModifier(
            item: item,
            title: title,
            message: message,
            showTwoButtons: showTwoButtons,
            cancelTitle: cancelTitle,
            okTitle: okTitle,
            emoji: emoji,
            isConfirmInvite: isConfirmInvite,
            onOK: onOK)
        )
    }
    
    func respondItemCustomAlert(item: Binding<String?>, type: RespondPopupInfo, onOK: @escaping (String) -> Void) -> some View {
        modifier(CustomAlertItemModifier(
            item: item,
            title: type.title,
            message: type.message(),
            showTwoButtons: true,
            cancelTitle: type.cancel,
            okTitle: type.understand,
            emoji: "🦥",
            isConfirmInvite: true, onOK: onOK)
        )
    }
}
