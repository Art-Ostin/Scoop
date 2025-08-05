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







/*
 struct ClockView<Content: View>: View {
     
     let meetUpTime: Date
     
     @State private var timeRemaining = DateComponents()
     private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
     
     var body: some View {
         
         HStack(spacing: 32) {
             clockSection(time: timeRemaining.hour ?? 0, sign: "hr")
             clockSection(time: timeRemaining.minute ?? 0, sign: "m")
             clockSection(time: timeRemaining.second ?? 0, sign: "s")
         }
         .foregroundStyle(.white)
         .frame(width: 253, height: 52)
         .background(Color.accent)
         .cornerRadius(15)
         .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
         .onReceive(timer) { _ in updateTimeRemaining() }
         .onAppear { updateTimeRemaining() }
     }
     
     
     
     private func clockSection(time: Int, sign: String) -> some View {
         HStack(spacing: 5) {
             Text(String(format: "%02d", max(0, time)))
                 .font(.custom("SFCompactRounded-Semibold", size: 28))
             Text(sign)
                 .font(.custom("SFCompactRounded-Regular", size: 14))
                 .offset(y: 5)
         }
     }
     
     private func updateTimeRemaining() {
         timeRemaining = Calendar.current.dateComponents([
             .hour,
             .minute,
             .second
         ], from: Date(), to: meetUpTime)
     }
 }
 */
