//
//  InvitedTimeCell.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.

import SwiftUI

struct InvitedTimeCell: View {

    //Injected
    @Environment(\.timeCustomMenuDismiss) private var dismissMenu
    @Binding var selectedDay: Date?
    @Binding var responseType: ResponseType
    let status: TimeStatus
    let date: Date
    let idx: Int

    //Local view state
    @State private var shake = false        // toggled to fire a shake
    @State private var isShaking = false    // true while the warning text flashes yellow

    private var isSelected: Bool { selectedDay == date }

    var body: some View {
        
        Button {
            clickCell()
        } label: {
            timeCellLabel
        }
        .shrinkButton()
        .task(id: isShaking) {await resetShakeFlag()}
    }
}

extension InvitedTimeCell {
    
    private var timeCellLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            optionTypeText
            eventTimeText
        }
        .invitedTimeCellBackground(isSelected, isAvailable: status == .available)
        .overlay(alignment: .topTrailing) {timeStatusText}
        .showShakeAnimation(bool: shake)
    }
        
    private var optionTypeText: some View {
        Text("Option \(idx + 1)")
            .font(.body(14, .medium))
            .foregroundStyle(isSelected ? Color.successGreen : Color.textTertiary)
    }
    
    private var eventTimeText: some View {
        let (weekday, month, hour) = formattedDateParts
        return Group {
            Text("\(weekday) \(month) ·").font(.body(16, status != .available ? .regular : .medium))
            +
            Text(" \(hour)").font(.body(14)).foregroundStyle(Color.textTertiary)
        }
        .opacity(status != .available ? 0.6 : 1)
    }
    
    private var formattedDateParts: (weekday: String, month: String, hour: String) {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let month = date.formatted(.dateTime.month(.wide).day())
        let hour = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        return (weekday, month, hour)
    }
    
    @ViewBuilder
    private var timeStatusText: some View {
        if status != .available {
            Text(status.rawValue)
                .font(.body(12, .italic))
                .foregroundStyle(isShaking ? Color.warningYellow : Color.textTertiary)
                .animation(.easeInOut(duration: 0.2), value: isShaking)
                .padding(.horizontal)
                .padding(.top, 12)
        }
    }
}

//Logic for clicking a time
extension InvitedTimeCell {
    
    private func clickCell() {
        guard checkIfTimeIsAvailable() else { return}
        updateTimeAndDismissPopup()
    }
    
    private func checkIfTimeIsAvailable() -> Bool {
        guard status == .available else {
            shake.toggle()
            isShaking = true
            return false
        }
        return true
    }
    
    private func updateTimeAndDismissPopup() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDay = date
            responseType = .original
            dismissMenu()
        }
    }
    
    private func resetShakeFlag()  async  {
        guard isShaking else { return }
        try? await Task.sleep(for: .seconds(1))
        withAnimation { isShaking = false }
    }
}

//Background for popup
extension View {
    func invitedTimeCellBackground(_ isSelected: Bool, isAvailable: Bool) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
            .opacity(isAvailable ? 0.4 : 1)
            .stroke(CornerRadius.md, lineWidth: 1, color: isSelected ? Color.successGreen.opacity(0.35) : Color.border)
    }
}
