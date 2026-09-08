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
        .buttonStyle(.plain)
        .task(id: isShaking) {await resetShakeFlag()}
    }
}

extension InvitedTimeCell {
    
    private var timeCellLabel: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            optionTypeText
            eventTimeText
        }
        .invitedTimeCellBackground(isSelected)
        .overlay(alignment: .topTrailing) {timeStatusText}
        .showShakeAnimation(bool: shake)
    }
        
    private var optionTypeText: some View {
        Text("Option \(idx + 1)")
            .font(.body(15, .medium))
            .foregroundStyle(isSelected ? Color.textAccent : Color.textTertiary)
    }
    
    private var eventTimeText: some View {
        let time = FormatEvent.shortDayAndTime(date, withHour: false) //The hour follows below in its own tone; `shortDayAndTime` appends one by default
        let hour = FormatEvent.hourTime(date)
        return Group {
            Text(time)
                .font(.body(17, status != .available ? .regular : .medium))
                .foregroundStyle(Color.textPrimary)
            +
            Text(" · \(hour)").font(.body(15)).foregroundStyle(Color.textTertiary)
        }
        .opacity(status != .available ? 0.6 : 1)
    }
    
    @ViewBuilder
    private var timeStatusText: some View {
        if status != .available {
            Text(status.rawValue)
                .font(.body(13, .italic))
                .foregroundStyle(isShaking ? Color.warningYellow : Color.textTertiary)
                .animation(.transition, value: isShaking)
                .padding(.horizontal)
                .padding(.top, Spacing.sm)
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
        selectedDay = date
        responseType = .originalInvite
        dismissMenu()
    }
    
    private func resetShakeFlag()  async  {
        guard isShaking else { return }
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.transition) { isShaking = false }
    }
}

//Background for popup
extension View {
    func invitedTimeCellBackground(_ isSelected: Bool) -> some View {
        self
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
            .stroke(CornerRadius.md, lineWidth: 1, color: isSelected ? Color.accent.opacity(0.35) : Color.border)
    }
}

/*
 
 private var formattedDateParts: (weekday: String, month: String, hour: String) {
     
     
     
     let weekday = date.formatted(.dateTime.weekday(.wide))
     let month = date.formatted(.dateTime.month(.wide).day())
     let hour = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
     return (weekday, month, hour)
 }

 */
