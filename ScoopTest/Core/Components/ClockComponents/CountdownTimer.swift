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
    
    init (targetTime: Date, @ViewBuilder content: @escaping (DateComponents) -> Content) {
        self.targetTime = targetTime
        self.content = content
    }
    
    var body: some View {
        content(timeRemaining)
        .onReceive(timer) { _ in updateTimeRemaining() }
        .onAppear { updateTimeRemaining() }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = Calendar.current.dateComponents([
            .hour,
            .minute,
            .second
        ], from: Date(), to: targetTime)
    }
}
