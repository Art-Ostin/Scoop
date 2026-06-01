//
//  SettingsButton.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

 import SwiftUI

struct InfoButton: View {
    @Binding var showScreen: Bool
    var isAtTopOfScroll: Bool = true
    
    var body: some View {
        Group {
            if !isAtTopOfScroll {
                GlassButton(action: {showScreen  = true}) {
                    Image(systemName: "info.circle")
                        .font(.body(18, .medium))
                }
                .transition(.blurReplace.combined(with: .scale(0.8, anchor: .top)))
                .padding(.top, 16) //As its small icon, sits in correct position
                .padding(.horizontal, 22)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isAtTopOfScroll)
    }
}

//Settings Button
 struct SettingsButton: View {
     let zoomNS: Namespace.ID
     let action: () -> Void
     var body: some View {
         GlassButton(padding: 2, action: action) {
             Image(systemName: "gear")
                 .font(.body(20, .medium))
                 .matchedTransitionSource(id: "settings", in: zoomNS)
         }
     }
 }


extension View {

    @ViewBuilder
    func glassButtonStyleIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.plain)
        }
    }

    @ViewBuilder
    func glassProminentButtonStyleIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.plain)
        }
    }
}

//To disappear when it is not at the top.
private struct ScrollTopTracker: ViewModifier {
    @Binding var isAtTop: Bool
    @State private var expandedInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.top } action: { _, inset in
                expandedInset = max(expandedInset, inset)
                isAtTop = inset >= expandedInset - 1
            }
            .onAppear {
                expandedInset = 0
                isAtTop = true
            }
    }
}

extension View {
    func trackTopOfScroll(_ isAtTop: Binding<Bool>) -> some View {
        modifier(ScrollTopTracker(isAtTop: isAtTop))
    }
}


/*
 
 
 
 Button(action: action) {
     Image(systemName: "gear")
         .resizable()
         .scaledToFit()
         .frame(width: 20, height: 20)
         .frame(width: 35, height: 35)
         .hoverButton(Circle())
         .contentShape(Circle())
         .foregroundStyle(Color.black)
         .matchedTransitionSource(id: "settings", in: zoomNS)
 }

 */
