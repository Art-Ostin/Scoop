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
    var isCardAccept: Bool = false
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0){
                proposedDays
                hourIfNeeded
            }
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, -12)
            
            DropDownChevron(showTimePopup: $showTimePopup)
                .offset(x: isAccept ? 2.6 : 4)
                .fixedSize()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .lineSpacing(1)
    }
    
    private var datesText: some View {
        var result = Text("")
        for (index, date) in dates.enumerated() {
            result = result
            + Text(FormatEvent.dayAndTime(date, wide: isAccept ? false : (dates.count != 3 ? true : false) , withHour: false))
            + Text(index == dates.count - 1 ? (dates.count != 3 && isAccept ?  " · " :"") : ",  ")
        }
        if dates.count != 3 && isAccept {
            result = result + Text(FormatEvent.hourTime(dates.last ?? Date()))
        }
        return result.frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension ProposedTimesRow {
    
    private  var proposedDays: some View {
        Group {
            if dates.count == 0 {
                Text("Select Time")
                    .font(.body(15, .medium))
                    .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
                
            } else if dates.count == 1 {
                Text(FormatEvent.dayAndTime(dates.first ?? Date(), withHour: true))
                    .font(.body(17, .medium))
            } else {
                datesText
                    .font(.body(17, .medium))
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
        .minimumScaleFactor(isCardAccept ? 1 : 0.8)
        .allowsTightening(true)
    }
    
    @ViewBuilder
    private var hourIfNeeded: some View {
        if (isAccept && dates.count == 3) || (!isAccept && dates.count > 1) {
            if let firstTime = dates.first {
                Text(FormatEvent.hourTime(firstTime))
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
            }
        }
    }
}

