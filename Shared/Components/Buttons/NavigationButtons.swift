//
//  CloseViewButton.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

enum DismissType { case back, cross}

// MARK: Dismiss Button when .toolbar is available

///Customised Navigation dismiss button. Usage: .toolbar{DismissToolbarItem(.back)}
struct DismissToolbarItem: ToolbarContent {

    @Environment(\.dismiss) private var dismiss
    
    private let dismissType: DismissType
    var isLeading: Bool
    
    //Custom init used so can call it with just .back
    init(_ dismissType: DismissType, isLeading: Bool = true) {
        self.dismissType = dismissType
        self.isLeading = isLeading
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: isLeading ? .topBarLeading : .topBarTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: dismissType == .cross ? "xmark" : "chevron.left")
                    .font(.system(size: dismissType == .cross ? 12 : 14, weight: .heavy))
            }
        }
    }
}

// MARK: Dimiss Button when .toolbar not availble
struct DismissButton: View {
     
    @Environment(\.dismiss) private var dismiss

    let dismissType: DismissType
    private let action: (() -> Void)?

    init(_ dismissType: DismissType, action: (() -> Void)? = nil) {
        self.dismissType = dismissType
        self.action = action
    }

    private func handleTap() {
        if let action { action() } else { dismiss() }
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            Button {
                handleTap()
            } label: {
                buttonLabel
            }
            .foregroundStyle(Color.black)
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(.clear)
        } else {
            Button {
                handleTap()
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


// MARK: Dimsiss Button with Check, triggering alert


struct CloseAndCheckNavButton: ViewModifier {
    @Environment(\.dismiss)var dismiss
    let check: Bool
    @Binding var triggerAlert: Bool

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if check {
                            triggerAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 30, height: 50) //Frame Solves a bug for quick dismissing
                            .contentShape(Rectangle())
                    }
                }
            }
    }
}

extension View {
    func closeAndCheckNavButton(check: Bool, triggerAlert: Binding<Bool>) -> some View {
        modifier(CloseAndCheckNavButton(check: check, triggerAlert: triggerAlert))
    }
}
