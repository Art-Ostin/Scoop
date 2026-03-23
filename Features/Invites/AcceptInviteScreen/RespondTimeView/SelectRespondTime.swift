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

    @Bindable var vm: TimeAndPlaceViewModel
    @Binding var selectedDay: Date?
    @Binding var showTime: Bool
    
    let times: [ProposedTime]

    @State var showCustomTime: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            timeDropDownTitle
            
            if showCustomTime {
                SelectTimeView(vm: vm, showTimePopup: $showTime, isRespondMode: true, showInvitedTimes: $showCustomTime)
            } else {
                proposedTimes
            }
        }
        .frame(width: 290, alignment: .leading)
        .padding([.horizontal, .top], 18)
        .padding(.bottom, showCustomTime ? 0 : 18)
        .background(CardBackground(cornerRadius: 16))
    }
}

extension SelectRespondTime {
    
    
    private var proposedTimes: some View {
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
            Text(showCustomTime ? "Propose new Time" : "Invited Days")
                .font(.custom("SFProRounded-Medium", size: 16))
                .foregroundStyle(Color.grayText)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {showCustomTime.toggle()}
            } label: {
                if showCustomTime {
                    Text("Options")
                        .foregroundStyle(Color.appGreen)
                        .font(.custom("SFProRounded-Bold", size: 12))
                        .padding(4)
                        .kerning(0.5)
                        .padding(.horizontal, 6)
                        .stroke(16, lineWidth: 1, color: Color.appGreen.opacity(0.2))
                        .offset(y: -2)
                } else {
                    Text("Can't make it?")
                        .font(.body(12, .bold))
                        .foregroundStyle((Color(red: 0.45, green: 0.45, blue: 0.45)))
                        .kerning(0.5)
                }
            }
        }
    }
}
