//
//  RespondTimeDropDown.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//

import SwiftUI

enum TimeStatus: String {
    case available, unavailable, expired
}


struct SelectRespondTime: View {

    @Binding var selectedDay: Date?
    @Binding var showTime: Bool
    
    let times: [ProposedTime]

    @Binding var showCustomTime: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            timeDropDownTitle
            
            ForEach(times.indices, id: \.self) {idx in
                let time = times[idx]
                let status = getTimeStatus(time)
                dayRow(idx: idx, date: time.date , status: status)
            }
        }
        .frame(width: 290, alignment: .leading)
        .padding(18)
        .background(CardBackground(cornerRadius: 16))
    }
}

extension SelectRespondTime {
    
    //A time might be unavailable either because other user has new commitment or it has expired, this function checks for both
    private func getTimeStatus(_ time: ProposedTime) -> TimeStatus {
        if !time.stillAvailable {
            //1. If it more than six hours in future and not availble it means new commitment. If less than this it was expired.
            if time.date > Date.now.addingTimeInterval(6 * 60 * 60) {
                return .unavailable
            } else {
                return .expired
            }
        }
        return .available
    }
    
    @ViewBuilder
    private func dayRow(idx: Int, date: Date, status: TimeStatus) -> some View {
        let isSelected = selectedDay == date
        
        Button {
            selectedDay = date
            showTime = false
        } label : {
            VStack(alignment: .leading, spacing: 4) {
                Text("Option \(idx + 1)")
                    .font(.body(14, .medium))
                    .foregroundStyle(isSelected ? Color.appGreen : Color.grayText)
                
                eventTime(date: date)
                    .opacity(0.2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background (
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .stroke(16, lineWidth: 1, color: isSelected ? Color.appGreen.opacity(0.35) : Color.grayBackground)
            .overlay(alignment: .topTrailing) {
                if true { //!(status == .available)
                    Text("Expired") //status.rawValue
                        .font(.body(12, .italic))
                        .foregroundStyle(Color.grayText)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }
            }
        }
        .disabled(status != .available)
    }
    
    private var timeDropDownTitle: some View {
        HStack {
            Text("Invited Days")
                .font(.custom("SFProRounded-Medium", size: 16))
                .foregroundStyle(Color.grayText)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCustomTime = true
                }
            } label: {
                Text("Can't make it?")
                    .font(.body(12, .bold))
                    .foregroundStyle((Color(red: 0.45, green: 0.45, blue: 0.45)))
                    .kerning(0.5)
            }
        }
    }
    
    @ViewBuilder
    private func eventTime(date: Date) -> some View {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let month = date.formatted(.dateTime.month(.wide).day())
        let hour =  date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        
        Text("\(weekday) \(month) ·")
            .font(.body(16, .medium))
        +
        Text(" \(hour)")
            .font(.body(14))
            .foregroundStyle(Color.grayText)
    }
    
    
}
