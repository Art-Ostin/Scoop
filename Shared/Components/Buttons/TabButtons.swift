//
//  SettingsButton.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

 import SwiftUI

 struct SettingsButton: View {
     let zoomNS: Namespace.ID
     let action: () -> Void
     var body: some View {
         Button(action: action) {
             Image(systemName: "gear")
                 .resizable()
                 .scaledToFit()
                 .frame(width: 20, height: 20)
                 .frame(width: 35, height: 35)
                 .glassIfAvailable(Circle())
                 .contentShape(Circle())
                 .foregroundStyle(Color.black)
                 .matchedTransitionSource(id: "settings", in: zoomNS)
         }
     }
 }


import SwiftUI

struct TabInfoButton: View {
    @Binding var showScreen: Bool
    let isAtTopOfScroll: Bool
    var body: some View {
        Group {
            if isAtTopOfScroll {
                Button {
                    showScreen = true
                } label: {
                    Image(systemName: "info.circle")
                        //1. Logic for Icon
                        .font(.body(18, .medium))
                        .foregroundStyle(Color.black)
                        .contentShape(Circle())

                }
                //3. Retracts up into the nav bar with a soft glass blur
                .transition(.blurReplace.combined(with: .scale(0.8, anchor: .top)))
                .buttonBorderShape(.circle)
                .glassButtonStyleIfAvailable()
                .padding(.top, 16) //As its small icon, sits in correct position
                .padding(.horizontal, 22)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isAtTopOfScroll)
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
