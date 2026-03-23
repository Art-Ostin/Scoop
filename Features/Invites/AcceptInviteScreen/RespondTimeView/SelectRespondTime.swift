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
            
            if showCustomTime {
                
            } else {
                proposedDays
            }
        }
        .frame(width: 290, alignment: .leading)
        .padding(18)
        .background(CardBackground(cornerRadius: 16))
    }
}

extension SelectRespondTime {
    
    
    private var proposedDays: some View {
        ForEach(times.indices, id: \.self) {idx in
            let time = times[idx]
            let status = getTimeStatus(time)
            InvitedTimeCell(selectedDay: $selectedDay, showTime: $showTime, status: status, date: time.date, idx: idx)
        }
    }
    
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
    
    private var timeDropDownTitle: some View {
        HStack {
            Text("Invited Days")
                .font(.custom("SFProRounded-Medium", size: 16))
                .foregroundStyle(Color.grayText)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCustomTime.toggle()
                }
            } label: {
                
                
                
                
                Text("Can't make it?")
                    .font(.body(12, .bold))
                    .foregroundStyle((Color(red: 0.45, green: 0.45, blue: 0.45)))
                    .kerning(0.5)
            }
        }
    }
}
