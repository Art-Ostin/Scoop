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

    @State var showCustomTime: Bool = false
    private let cornerRadius: CGFloat = 16
    private let horizontalInset: CGFloat = 18
    private let contentWidth: CGFloat = 290
    
    private var cardWidth: CGFloat {
        contentWidth + (horizontalInset * 2)
    }
        
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            timeDropDownTitle
                .padding(.horizontal, horizontalInset)
            contentViewport
        }
        .frame(width: cardWidth, alignment: .leading)
        .padding(.top, horizontalInset)
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .background(CardBackground(cornerRadius: cornerRadius))
        .animation(.smooth(duration: 0.2), value: showCustomTime)
    }
}

extension SelectRespondTime {

    private var contentViewport: some View {
        ZStack(alignment: .topLeading) {
            if showCustomTime {
                transitionScreen {
                    customTimeView
                }
                .transition(.move(edge: .trailing))
                    .zIndex(1)
            } else {
                transitionScreen {
                    proposedTimes
                }
                .transition(.move(edge: .leading))
                .zIndex(0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped(antialiased: true)
        .customHorizontalScrollFade(width: horizontalInset, showFade: true, fromLeading: true)
        .customHorizontalScrollFade(width: horizontalInset, showFade: true, fromLeading: false)
    }
    
    private func transitionScreen<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, horizontalInset)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
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
            Text(showCustomTime ? "Propose New Time" : "Invited Times")
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
/*
 //
 //        Text("Options")
 //            .foregroundStyle(Color.appGreen)
 //            .font(.custom("SFProRounded-Bold", size: 12))
 //            .kerning(0.5)
 //            .padding(4)
 //            .padding(.horizontal, 6)
 //            .stroke(16, lineWidth: 1, color: Color.appGreen.opacity(0.2))
 //            .offset(y: -2)

 */


////                    proposedTimes
/////                    customTimeView
