//
//  InvitedTimeCell.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.


import SwiftUI

struct InvitedTimeCell: View {
    
    @Binding var selectedDay: Date?
    @Binding var showTime: Bool
    
    let status: TimeStatus
    let date: Date
    let idx: Int
    var isSelected: Bool { selectedDay == date}
    
    var body: some View {
        Button {
            selectedDay = date
            showTime = false
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                optionType
                eventTime
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background (RoundedRectangle(cornerRadius: 16).fill(Color.white))
            .opacity(status != .available ? 0.4 : 1)
            .stroke(16, lineWidth: 1, color: isSelected ? Color.appGreen.opacity(0.35) : Color.grayBackground)
            .overlay(alignment: .topTrailing) {if (status != .available) {timeStatus}}
        }
        .disabled(status != .available)
    }
}

extension InvitedTimeCell {
    
    private var timeStatus: some View {
        Text(status.rawValue)
            .font(.body(12, .italic))
            .foregroundStyle(Color.grayText)
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
                .font(.body(16, .medium))
            +
            Text(" \(hour)")
                .font(.body(14))
                .foregroundStyle(Color.grayText)
        }
    }
    
}
