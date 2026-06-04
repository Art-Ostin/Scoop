//
//  MatchedGeometryEffectTest.swift
//  Scoop Test
//
//  Created by Art Ostin on 03/06/2026.
//

import SwiftUI

struct MatchedGeometryEffectTest: View {
    @State private var expanded = false
    @Namespace private var ns

    var body: some View {
        ZStack {
            if !expanded {
                NavigationStack {
                    Color.appCanvas.ignoresSafeArea()
                        .navigationTitle("Messages")
                }
                settingsButton
            } else {
                expandedScreen
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expanded)
    }

    private var settingsButton: some View {
        glassCircle                                      // flexible shape, like the orange RoundedRectangle
            .matchedGeometryEffect(id: "hero", in: ns)   // anchors to the framed shape, not Button chrome
            .frame(width: 48, height: 48)
            .overlay {                                   // icon rides on top, outside the matched layer
                Image(systemName: "gear")
                    .font(.body(16, .medium))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 12)
            .padding(.trailing, 24)
            .onTapGesture { expanded.toggle() }
    }

    @ViewBuilder
    private var glassCircle: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: 24)
                .fill(.clear)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
        } else {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .brightness(0.06)
        }
    }

    private var expandedScreen: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(Color.orange)                          // the SAME shape, now full-screen
            .matchedGeometryEffect(id: "hero", in: ns)
            .ignoresSafeArea()
            .overlay {                                   // content rides on top
                VStack(spacing: 24) {
                    ForEach(0..<10) { i in
                        Text("How it works \(i)")
                    }
                }
                .onTapGesture { expanded.toggle() }
            }
    }
}
