//
//  TransitionExperiment.swift
//  Scoop
//
//  Created by Art Ostin on 20/01/2026.
//

import SwiftUI

enum SlideDirection { case leading, trailing }

struct Example: View {
    @State private var isPresented = false
    @State private var direction: SlideDirection = .trailing

    private var transition: AnyTransition {
        switch direction {
        case .leading:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal:   .move(edge: .trailing).combined(with: .opacity)
            )
        case .trailing:
            return .asymmetric(
                 insertion: .move(edge: .trailing).combined(with: .opacity),
                 removal:   .move(edge: .leading).combined(with: .opacity)
             )
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Button("Next (enter from trailing)") {
                    direction = .trailing
                    withAnimation(.spring()) { isPresented = true }
                }

                Button("Back (enter from leading)") {
                    direction = .leading
                    withAnimation(.spring()) { isPresented = true }
                }

                Button("Hide (exit to leading)") {
                    direction = .leading
                    withAnimation(.spring()) { isPresented = false }
                }

                Button("Hide (exit to trailing)") {
                    direction = .trailing
                    withAnimation(.spring()) { isPresented = false }
                }
            }

            if isPresented {
                SheetLikeView(isPresented: $isPresented)
                    .transition(transition)     // identity stays the same
                    .zIndex(1)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct SheetLikeView: View {
    @State private var counter = 0
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("I keep my state.")
            Button("Counter: \(counter)") { withAnimation {
                isPresented = false
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding()
        .offset(y: -144)
    }
}

#Preview {
    Example()
}
