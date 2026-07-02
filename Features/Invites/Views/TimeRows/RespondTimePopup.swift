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

struct RespondTimePopup: View {
    
    //1. To Dismiss the screen
    @Environment(\.timeCustomMenuDismiss) private var dismissMenu

    //2. Modify the draft
    @Binding var draft: RespondDraft
    
    //3.Card Layout Logic
    private let contentWidth: CGFloat = 280
    private let horizontalInset: CGFloat = 18
    private var cardWidth: CGFloat {
        contentWidth + (horizontalInset * 2)
    }
    
    //4. Tracks which view is showing: the invited times, or the custom new-time picker.
    @State private var showCustomTime: Bool = false
    

    var noAvailableDates: Bool {
        !draft.originalInvite.event.proposedTimes.dates.contains { getTimeStatus($0) == .available }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            timeDropDownTitle
                .padding(.horizontal, horizontalInset)
            contentViewport
        }
        .modifier(RespondTimeBackground(cardWidth: cardWidth))
        .onAppear {showCustomTime = (draft.respondType == .modified || noAvailableDates)}//Loads it up right view on launch
    }
}

//The Popup container
extension RespondTimePopup {
    private var contentViewport: some View {
        ZStack(alignment: .topLeading) {
            if showCustomTime {
                customTime
            } else {
                proposedTimesContainer
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped(antialiased: true)
        .customHorizontalScrollFade(width: horizontalInset, showFade: true, fromLeading: true)
        .customHorizontalScrollFade(width: horizontalInset, showFade: true, fromLeading: false)
    }
    
    private var customTime: some View {
        transitionScreen {
            SelectTimeView(proposedTimes: $draft.newTime.proposedTimes, isRespondMode: true)
        }
        .transition(.move(edge: .trailing))
        .zIndex(1)
    }
    
    private func transitionScreen<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, horizontalInset)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//Title and swich Button Logic
extension RespondTimePopup {
    
    private var timeDropDownTitle: some View {
        HStack {
            Text(showCustomTime ? "Invited Times" : "Propose New Time")
                .font(.title(16, .medium))
                .foregroundStyle(Color.grayText)
            Spacer()
            toggleViewButton
        }
    }
    
    private var toggleViewButton: some View {
        Button {
            switchView()
        } label: {
            if showCustomTime {
                optionsLabel
            } else {
                cantMakeItLabel
            }
        }
        .shrinkPress()
    }
    
    private var optionsLabel: some View {
        Text("Options")
            .foregroundStyle(Color.appGreen)
            .font(.title(12))
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
    
    private func switchView() {
        showCustomTime.toggle()
        if showCustomTime { //Only switch the type to modified, if I have modified selected
            if !draft.newTime.proposedTimes.dates.isEmpty { draft.respondType = .modified }
        } else {//Only switches if there are available dates
            if !noAvailableDates { draft.respondType = .original}
        }
    }
}

//ProposedTimeView Logic
extension RespondTimePopup {
    
    private var proposedTimesContainer: some View {
        transitionScreen {
            proposedTimes
        }
        .transition(.move(edge: .leading))
        .zIndex(0)
    }
    
    @ViewBuilder
    private var proposedTimes: some View {
        let orderedTimes = draft.originalInvite.event.proposedTimes.dates.sorted { $0.date < $1.date }
        
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(orderedTimes.enumerated()), id: \.offset) { idx, time in
                inviteTimeCell(idx, time)
            }
        }
        .padding(.bottom, 18)
    }
    
    @ViewBuilder
    private func inviteTimeCell(_ idx: Int, _ time: ProposedTime) -> some View {
        let status = getTimeStatus(time)
        InvitedTimeCell(
            selectedDay: $draft.originalInvite.selectedDay,
            responseType: $draft.respondType,
            status: status,
            date: time.date,
            idx: idx
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
}

struct RespondTimeBackground: ViewModifier {
    let horizontalInset: CGFloat = 18
    let cardWidth: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(width: cardWidth, alignment: .leading)
            .padding(.top, horizontalInset)
            .compositingGroup()
            .clipShape(.rect(cornerRadius: 16, style: .continuous))
            .rectangleStroke(radius: 16, lineWidth: 1, color: Color.grayBackground)
    }
}

//            .background(Color.appCanvas, in: .rect(cornerRadius: 16))

