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

struct RespondSelectTime: View {
    //Need vm here as modifying a lot
    @Bindable var vm: RespondViewModel
    @Binding var showTimePopup: Bool
    
    //UI State for code
    @State var showCustomTime: Bool = false
    private let horizontalInset: CGFloat = 18
    
    private var contentWidth: CGFloat {
        isRespondPopup ? 270 : 280
    }
    
    var isRespondPopup: Bool = false
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(customBackground)
        .animation(.smooth(duration: 0.2), value: showCustomTime)
    }
}

extension RespondSelectTime {

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
        SelectTimeView(proposedTimes: $vm.respondDraft.newTime.proposedTimes, type: vm.respondDraft.originalInvite.event.type, showTimePopup: $showTimePopup, isRespondMode: true, isRespondPopup: isRespondPopup)
    }
    
    @ViewBuilder
    private var proposedTimes: some View {
        let orderedTimes = vm.respondDraft.originalInvite.event.proposedTimes.dates.sorted { $0.date < $1.date }
        
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(orderedTimes.enumerated()), id: \.offset) { idx, time in
                let status = getTimeStatus(time)
                InvitedTimeCell(
                    selectedDay: $vm.respondDraft.originalInvite.selectedDay,
                    showTime: $showTimePopup,
                    responseType: $vm.respondDraft.respondType,
                    status: status,
                    date: time.date,
                    idx: idx
                )
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
                if vm.respondDraft.respondType == .original {
                    vm.respondDraft.respondType = .modified
                } else {
                    vm.respondDraft.respondType = .original
                }
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
    
    private var customBackground: some View {
        ZStack { //Background done like this to fix bugs when popping up
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.background)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 1)
        }
    }
}
