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
        static let titleToTimeSpacing: CGFloat = 14.25
        static let timeToPlaceSpacing: CGFloat = 16.5
        static let actionTopSpacing: CGFloat = 25
        
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
                .padding(.top, Layout.titleToTimeSpacing)
            
            InviteCardPlaceRow(showMessageSection: $showMessageScreen, location: event.location)
                .opacity(showTimePopup ? 0.3 : 1)
                .padding(.top, Layout.topPadding)
            
            responseRow
                .opacity(showTimePopup ? 0.3 : 1)
                .allowsHitTesting(!showTimePopup)
                .padding(.top, Layout.actionTopSpacing)
        }
        .padding(.horizontal, 20)
        .padding(.top, Layout.topPadding)
        .padding(.bottom, Layout.bottomPadding)
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
                .scaleEffect(0.9, anchor: .trailing)
                .fixedSize()
        }
    }
}
 struct QuickInviteTime: PreferenceKey {
     static var defaultValue: Bool = false
     static func reduce(value: inout Bool, nextValue: () -> Bool) {
         value = nextValue()
     }
 }

