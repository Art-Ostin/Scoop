//
//  InvitedTimeCell.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.

//Don't make InvitedTimeCell a button

import SwiftUI

struct InvitedTimeCell: View {
    
    @Binding var selectedDay: Date?
    @Binding var showTime: Bool
    @Binding var responseType: ResponseType
        
    let status: TimeStatus
    let date: Date
    let idx: Int
    var isSelected: Bool { selectedDay == date}
    
    //Shaking animation
    @State private var shake = false        // toggled to fire a shake
    @State private var isShaking = false    // true while the warning text flashes yellow
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 4) {
            optionType
            eventTime
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: .rect(cornerRadius: 16))
        .opacity(status != .available ? 0.4 : 1)
        .stroke(16, lineWidth: 1, color: isSelected ? Color.appGreen.opacity(0.35) : Color.grayBackground)
        .overlay(alignment: .topTrailing) {if (status != .available) {timeStatus}}
        .contentShape(.rect)
        .onTapGesture {clickCell()}
        .showShakeAnimation(bool: shake)
        .task(id: isShaking) {await resetShakeFlag()}
    }
}

extension InvitedTimeCell {
    
    private var timeStatus: some View {
        Text(status.rawValue)
            .font(.body(12, .italic))
            .foregroundStyle(isShaking ? Color.warningYellow : Color.grayText)
            .animation(.easeInOut(duration: 0.2), value: isShaking)
            .padding(.horizontal)
            .padding(.top, 12)
    }
    
    private var optionType: some View {
        Text("Option \(idx + 1)")
            .font(.body(14, .medium))
            .foregroundStyle(isSelected ? Color.appGreen : Color.grayText)
    }
    
    @ViewBuilder
    private var eventTime: some View {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let month = date.formatted(.dateTime.month(.wide).day())
        let hour =  date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        
        Group {
            Text("\(weekday) \(month) ·")
                .font(.body(16, status != .available ? .regular : .medium))
            +
            Text(" \(hour)")
                .font(.body(14))
                .foregroundStyle(Color.grayText)
        }
        .opacity(status != .available ? 0.6 : 1)
    }
    
    private func clickCell() {
        guard status == .available else {
            shake.toggle()
            isShaking = true
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDay = date
            responseType = .original
            showTime = false
        }
    }
    
    private func resetShakeFlag()  async  {
        guard isShaking else { return }
        try? await Task.sleep(for: .seconds(1))
        withAnimation { isShaking = false }
    }
}
