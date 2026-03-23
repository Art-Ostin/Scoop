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
    @Namespace private var contentNamespace

    let times: [ProposedTime]

    @State var showCustomTime: Bool = true
        
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            timeDropDownTitle
            
            ZStack(alignment: .topLeading) {
                if showCustomTime {
                    ClearRectangle(size: 200)
                        .transition(contentTransition)
                        .zIndex(1)
                }
                
                if !showCustomTime {
                    ClearRectangle(size: 100)
                        .transition(contentTransition)
                        .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
        }
        .frame(width: 290, alignment: .leading)
        .padding([.horizontal, .top], 18)
        .background(CardBackground(cornerRadius: 16)) //Not Issue
        .animation(.smooth(duration: 0.2), value: showCustomTime) //Not Issue
    }
}

extension SelectRespondTime {
    
    private var customTimeView: some View {
        SelectTimeView(vm: vm, showTimePopup: $showTime, isRespondMode: true, showInvitedTimes: $showCustomTime)
    }
    
    private var proposedTimes: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(times.indices, id: \.self) { idx in
                let time = times[idx]
                let status = getTimeStatus(time)
                InvitedTimeCell(selectedDay: $selectedDay, showTime: $showTime, status: status, date: time.date, idx: idx)
            }
        }
        .padding(.bottom, 18)
    }
    
    private var contentTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
            removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
        )
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
                    showCustomTime.toggle()
            } label: {
                if showCustomTime {
                    optionsLabel
                } else {
                    cantMakeItLabel
                }
            }
        }
    }
    
    private var optionsLabel: some View {
        Text("Options")
            .foregroundStyle(Color.appGreen)
            .font(.custom("SFProRounded-Bold", size: 12))
            .padding(4)
            .kerning(0.5)
            .padding(.horizontal, 6)
            .stroke(16, lineWidth: 1, color: Color.appGreen.opacity(0.2))
            .offset(y: -2)
    }
    
    private var cantMakeItLabel: some View {
        Text("Can't make it?")
            .font(.body(12, .bold))
            .foregroundStyle((Color(red: 0.45, green: 0.45, blue: 0.45)))
            .kerning(0.5)
    }
}

////                    proposedTimes
/////                    customTimeView
