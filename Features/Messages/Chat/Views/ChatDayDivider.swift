//
//  ChatDayDividers.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatDayDivider: View {
    
    let date: Date?
    
    var body: some View {
        if let date {
            Text(formatDay(day: date))
                .font(.body(12, .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .stroke(16, lineWidth: 1, color: Color.grayPlaceholder)
                .padding(.top, 16)
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
