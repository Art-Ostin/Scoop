//
//  DismissButtons.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

enum DismissType {
    case back, cross
    var symbolName: String { self == .cross ? "xmark" : "chevron.left" }
}

private extension Image {
    /// Shared size/weight for the toolbar dismiss & close glyphs, so the two can't drift.
    func dismissGlyphStyle() -> some View { font(.icon(14)) }
}

///Dismiss Button when Toolbar is available
struct DismissToolbarItem: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    
    let type: DismissType
    var isLeading: Bool = true
    var isDisabled: Bool = false

    var body: some ToolbarContent {
        ToolbarItem(placement: isLeading ? .topBarLeading : .topBarTrailing) {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: type.symbolName)
                    .dismissGlyphStyle()
            }
            .disabled(isDisabled)
        }
    }
}

///Dismiss Button when toolbar unavailable
struct DismissButton: View {
    @Environment(\.dismiss) private var dismiss
    let type: DismissType
    
    
    var body: some View {
        ScoopButton(shape: Circle(), size: .large, action: {dismiss()}) {
            Image(systemName: type.symbolName)
        }
    }
}

/// A pushed screen's veto over the back button its container owns. The flow's leading slot
/// holds ONE lens (see `EditProfileContainer.leadingAction`), so a screen that can refuse to
/// be left publishes its check here rather than drawing a second chevron the lens would cover.
private struct PopGuardKey: EnvironmentKey {
    static let defaultValue: Binding<(() -> Bool)?> = .constant(nil)
}

extension EnvironmentValues {
    /// Written by the pushed screen, read by the container's back button. `nil` = nothing to ask.
    var popGuard: Binding<(() -> Bool)?> {
        get { self[PopGuardKey.self] }
        set { self[PopGuardKey.self] = newValue }
    }
}

/// Refuses the pop while `invalid`, raising the screen's own alert instead.
struct CheckBeforePop: ViewModifier {
    let invalid: Bool
    @Binding var triggerAlert: Bool

    @Environment(\.popGuard) private var popGuard

    func body(content: Content) -> some View {
        content
            //Rewritten on every change: the closure has to answer with the validity at TAP time,
            //not the one captured when the screen appeared.
            .onChange(of: invalid, initial: true) {
                popGuard.wrappedValue = {
                    guard invalid else { return true }
                    triggerAlert = true
                    return false
                }
            }
            .onDisappear { popGuard.wrappedValue = nil }
    }
}

extension View {
    func checkBeforePop(invalid: Bool, triggerAlert: Binding<Bool>) -> some View {
        modifier(CheckBeforePop(invalid: invalid, triggerAlert: triggerAlert))
    }
}

