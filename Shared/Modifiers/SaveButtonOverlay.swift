//
//  SaveButtonOverlay.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI




private struct SavedFeedbackModifier<Value: Equatable>: ViewModifier {
    @Binding var isPresented: Bool
    let value: Value
    let dismissAfter: Duration
    let animation: Animation

    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onChange(of: value) {
                dismissTask?.cancel()
                withAnimation(animation) { isPresented = true }
                dismissTask = Task { @MainActor in
                    do {
                        try await Task.sleep(for: dismissAfter)
                    } catch {
                        return
                    }
                    guard !Task.isCancelled else { return }
                    withAnimation(animation) { isPresented = false }
                }
            }
            .onDisappear {
                dismissTask?.cancel()
                dismissTask = nil
                isPresented = false
            }
    }
}


extension View {
    
    func savedFeedback<Value: Equatable>( isPresented: Binding<Bool>, tracking value: Value, dismissAfter: Duration = .seconds(1), animation: Animation = .toggle) -> some View {
        modifier(SavedFeedbackModifier(
            isPresented: isPresented,
            value: value,
            dismissAfter: dismissAfter,
            animation: animation
        ))
    }
}
