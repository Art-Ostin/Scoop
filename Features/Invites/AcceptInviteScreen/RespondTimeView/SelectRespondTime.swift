//
//  RespondTimeDropDown.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//

import SwiftUI

struct SelectRespondTime: View {

    @Binding var selectedDay: Date?
    @Binding var showTime: Bool
    
    let dates: [Date]

    @Binding var showCustomTime: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            timeDropDownTitle
            
            ForEach(dates.indices, id: \.self) {idx in
                let date = dates[idx]
                availableDay(idx: idx, date: date)
            }
        }
        .frame(width: 290, alignment: .leading)
        .padding(18)
        .background(CardBackground(cornerRadius: 16))
    }
}

extension SelectRespondTime {
    @ViewBuilder
    private func availableDay(idx: Int, date: Date) -> some View {
        let isSelected = selectedDay == date
        
        Button {
            selectedDay = date
            showTime = false
        } label : {
            VStack(alignment: .leading, spacing: 4) {
                Text("Option \(idx + 1)")
                    .font(.body(14, .medium))
                    .foregroundStyle(isSelected ? Color.appGreen : Color.grayText)
                
                let weekday = date.formatted(.dateTime.weekday(.wide))
                let month = date.formatted(.dateTime.month(.wide).day())
                let hour =  date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
                
                Text("\(weekday) \(month) ·")
                    .font(.body(16, .medium))
                +
                Text(" \(hour)")
                    .font(.body(14))
                    .foregroundStyle(Color.grayText)
                
                //let formattedDate = "\(date.formatted(.dateTime.weekday(.wide))) \(date.formatted(.dateTime.month(.wide).day()))"
                //Text(formattedDate)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background (
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .stroke(16, lineWidth: 1, color: isSelected ? Color.appGreen.opacity(0.35) : Color.grayBackground)
        }
    }
    
    private var timeDropDownTitle: some View {
        HStack {
            Text("Invited Days")
                .font(.custom("SFProRounded-Medium", size: 16))
                .foregroundStyle(Color.grayText)
            Spacer()
            Button {
                showCustomTime = true
            } label: {
                Text("Can't make it?")
                    .font(.body(12, .bold))
                    .foregroundStyle((Color(red: 0.45, green: 0.45, blue: 0.45)))
                    .kerning(0.5)
            }
        }
    }
}
