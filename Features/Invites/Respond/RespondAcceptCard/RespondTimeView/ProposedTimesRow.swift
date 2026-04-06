//
//  ProposedTimes.swift
//  Scoop
//
//  Created by Art Ostin on 28/03/2026.
//

import SwiftUI

struct ProposedTimesRow: View {
    
    let dates: [Date]
    @Binding var showTimePopup: Bool
    
    var isAccept: Bool = true
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 12) {
            Group {
                if dates.count == 0 {
                    Text("Select a day to meet")
                        .font(.body(15, .italic))
                    
                } else if dates.count == 1 {
                    Text(FormatEvent.dayAndTime(dates.first ?? Date(), withHour: true))
                        .font(.body(16, .medium))
                } else {
                    datesText
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .allowsTightening(true)
            DropDownChevron(showTimePopup: $showTimePopup)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var datesText: some View {
        var result = Text("")
        for (index, date) in dates.enumerated() {
            result = result
            + Text(FormatEvent.dayAndTime(date, wide: false, withHour: false))
            + Text(dates.count != 3 ? (index == dates.count - 1 ? " · ": ",  ") : "")
        }
        if dates.count != 3 {
            result = result + Text(FormatEvent.hourTime(dates.last ?? Date()))
        }
        return result.frame(maxWidth: .infinity, alignment: .leading).font(.body(16, .medium))
    }
}
