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
                .stroke(16, lineWidth: 1, color: .grayPlaceholder)
                .padding(.top, 16)

        }
    }
    func formatDay(day: Date) -> String {
        let cal = Calendar.current
        let now = Date()
        
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        
        let startDay = cal.startOfDay(for: day)
        let startNow = cal.startOfDay(for: now)
        let diffDays = cal.dateComponents([.day], from: startDay, to: startNow).day ?? 0
        
        // 2–6 days ago → weekday name
        if (2...6).contains(diffDays) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "EEEE" // Wednesday
            return df.string(from: day).capitalized(with: .current)
        }
        
        // 7+ days ago (or future) → "Tue 3 Feb"
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "EEE d MMM"
        return df.string(from: day)
    }
}
