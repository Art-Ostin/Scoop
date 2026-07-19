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

///Dismiss Button with check used for onboarding
struct CloseAndCheckNavButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let check: Bool
    @Binding var triggerAlert: Bool
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { check ? (triggerAlert = true) : dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .dismissGlyphStyle()
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

