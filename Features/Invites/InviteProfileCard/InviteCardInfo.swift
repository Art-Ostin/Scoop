//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardInfo: View {
    
    @State var showEventDetails: Bool = false
    
    @Bindable var vm: RespondViewModel
    let image: UIImage?
    let name: String
    
    let eventProfile: EventProfile
    
    var event: UserEvent {
        eventProfile.event
    }
    
    @State var selectedDay: Date?
    
    @State var newProposedDates: [Date]? = nil
    @State var showProposeDate: Bool = false
    
    var isPopup: Bool {
        image != nil
    }
 
    @Binding var showTimePopup: Bool
    @Binding var showMessageScreen: Bool
    
    private var hasMessage: Bool {
        event.message?.isEmpty != false
    }
    
    private enum Layout {
        static func titleToTimeSpacing(_ hasMessage: Bool) -> CGFloat {
            hasMessage ? 14 : 14 //10
        }
        static func timeToPlaceSpacing(_ hasMessage: Bool) -> CGFloat {
            hasMessage ? 18.5 : 18.5 //10.5
        }
        static func actionTopSpacing(_ hasMessage: Bool) -> CGFloat {
            hasMessage ? 24 : 24 //16
        }
        
        static let topPadding: CGFloat = 12
        static let bottomPadding: CGFloat = 10
    }

    init(vm: RespondViewModel, image: UIImage?, name: String, eventProfile: EventProfile , showTimePopup: Binding<Bool>, showMessageScreen: Binding<Bool>) {
        self.image = image
        self.name = name
        self.eventProfile = eventProfile
        self.vm = vm
        self._selectedDay = State(initialValue: eventProfile.event.proposedTimes.firstAvailableDate)
        self._showTimePopup = showTimePopup
        self._showMessageScreen = showMessageScreen
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            InviteCardTimeRow(selectedDay: selectedDay, showMessageScreen: $showMessageScreen, showTimePopup: $showTimePopup, vm: vm)
                .padding(.top, Layout.titleToTimeSpacing(hasMessage))
            
            InviteCardPlaceRow(location: event.location)
                .opacity(showTimePopup ? 0.3 : 1)
                .padding(.top, Layout.timeToPlaceSpacing(hasMessage))

            responseRow
                .opacity(showTimePopup ? 0.3 : 1)
                .allowsHitTesting(!showTimePopup)
                .padding(.top, Layout.actionTopSpacing(hasMessage))
        }
        .padding(.horizontal, 20)
        .padding(.top, Layout.topPadding)
        .padding(.bottom, Layout.bottomPadding)
        .overlay(alignment: .leading) {
            addMessageButton
        }
    }
}

extension InviteCardInfo {
    
    private var responseRow: some View {
        HStack {
            DeclineButton { }
            Spacer()
            AcceptButton {}
        }
    }
    
    private var title: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text("\(name)'s Invite")
                .font(.custom("SFProRounded-Bold", size: 20))
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InviteRespondButton(type: event.type, isFlipped: $showEventDetails)
                .scaleEffect(0.9)
                .fixedSize()
        }
    }
    
    private var addMessageButton: some View {
        Button {
            showMessageScreen = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName:"plus")
                    .font(.system(size: 10, weight: .bold))
                
                Text("Add note")
                    .font(.custom("SFProRounded-Bold", size: 11))
                    .kerning(0.4)
            }
            .foregroundStyle(Color.grayText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.92))
            }
            .stroke(24, lineWidth: 1, color: Color.grayBackground)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(.rect)
        }
        .offset(y: 20)
    }
}

struct QuickInviteTime: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
