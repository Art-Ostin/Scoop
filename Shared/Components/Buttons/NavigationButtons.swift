//
//  NavigationButtons.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

enum DismissType {
    case back, cross
    var symbolName: String { self == .cross ? "xmark" : "chevron.left" }
}

// MARK: - Dismiss Button when .toolbar is available

/// Customised Navigation dismiss button. Usage: .toolbar { DismissToolbarItem(.back) }
struct DismissToolbarItem: ToolbarContent {

    @Environment(\.dismiss) private var dismiss

    private let dismissType: DismissType
    private let isLeading: Bool

    init(_ dismissType: DismissType, isLeading: Bool = true) {
        self.dismissType = dismissType
        self.isLeading = isLeading
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: isLeading ? .topBarLeading : .topBarTrailing) {
            Button { dismiss() } label: {
                Image(systemName: dismissType.symbolName)
                    .font(.system(size: 14, weight: .heavy))
            }
        }
    }
}

// MARK: - Dismiss Button when .toolbar not available

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
            Button { dismiss() } label: {
                buttonLabel
                    .padding(6)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(.clear)
        } else {
            Button { dismiss() } label: {
                buttonLabel
                    .padding(15)
                    .background(Circle().fill(.ultraThinMaterial).brightness(0.065))
            }
            .customButtonGrowAndShadow(.customGlassShadow)
        }
    }

    private var buttonLabel: some View {
        Image(systemName: dismissType.symbolName)
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(Color.black)
    }
}

// MARK: - Dismiss Button with Check, triggering alert

struct CloseAndCheckNavButton: ViewModifier {

    @Environment(\.dismiss) private var dismiss
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
                            .font(.system(size: 14, weight: .heavy))
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
