//
//  ClockTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct CountdownTimer<Content: View>: View {
    
    @State private var timeRemaining = DateComponents()
        
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    let targetTime: Date
    let content: (DateComponents) -> Content
    let onFinished: () -> Void
    
    init (targetTime: Date, onFinished: @escaping () -> Void = {}, @ViewBuilder content: @escaping (DateComponents) -> Content) {
        self.targetTime = targetTime
        self.onFinished = onFinished
        self.content = content
    }
    
    var body: some View {
        content(timeRemaining)
            .onReceive(timer) { _ in updateTimeRemaining() }
            .onAppear { updateTimeRemaining() }
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        if now >= targetTime {
            timeRemaining = DateComponents(hour: 0, minute: 0, second: 0)
            onFinished()
            print("Is done")
            return
        }
        timeRemaining = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: targetTime)
    }
}

