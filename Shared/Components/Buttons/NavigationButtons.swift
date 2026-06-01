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

///Dismiss Button when Toolbar is available
struct DismissToolbarItem: ToolbarContent {

    @Environment(\.dismiss) private var dismiss
    
    let type: DismissType
    var isLeading: Bool = true

    var body: some ToolbarContent {
        ToolbarItem(placement: isLeading ? .topBarLeading : .topBarTrailing) {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: type.symbolName)
                    .font(.system(size: 14, weight: .heavy))
            }
        }
    }
}

///Dismiss Button when toolbar unavailable
struct DismissButton: View {
    
    @Environment(\.dismiss) private var dismiss
    let type: DismissType
    
    var body: some View {
        GlassCircleButton(padding: 6, action: dismiss.callAsFunction) {
            Image(systemName: type.symbolName)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Color.black)
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

