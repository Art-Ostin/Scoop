//
//  ChatDayDivider.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatDayDivider: View {
    
    let date: Date?

    //The divider's laid-out height — its taller line plus its top padding — so a sent row that opens a new day
    //can grow the divider in on the send's shift curve
    static var height: CGFloat {
        max(UIFont.body(12, .bold).lineHeight, UIFont.body(12, .regular).lineHeight) + Spacing.sm
    }
    
    var body: some View {
        if let date {
            HStack(spacing: Spacing.xs) {
                Text(formatDay(day: date))
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.textTertiary)
                    
                Text(date.formatted(.dateTime.hour().minute()))
                    .font(.body(12, .regular))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.top, Spacing.sm)
        }
    }
    
    func formatDay(day: Date) -> String {
        let cal = Calendar.current
        let now = Date()
        
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        
        let diffDays = cal.dateComponents([.day], from: cal.startOfDay(for: day), to: cal.startOfDay(for: now)).day ?? 0
        
        if (2...6).contains(diffDays) {
            return day.formatted(.dateTime.weekday(.wide))
                .capitalized(with: .current)
        }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
    
}
