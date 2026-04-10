//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardInfo: View {
    
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
    
    
    private enum Layout {
        static let titleToTimeSpacing: CGFloat = 24.5
        static let timeToPlaceSpacing: CGFloat = 26
        static let actionTopSpacing: CGFloat = 21

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
            timeView
                .padding(.top, Layout.titleToTimeSpacing)
            
            placeRow
                .opacity(showTimePopup ? 0.3 : 1)
                .padding(.top, Layout.timeToPlaceSpacing)

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
                .font(.custom("SFProRounded-Bold", size: 18))
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            eventTypeButton
                .scaleEffect(0.9)
                .fixedSize()
        }
    }
    
    private var eventTypeButton: some View {
        Button {
//            isFlipped.toggle()
        } label: {
            HStack(spacing: 0) {
                Text("\(event.type.description.emoji)\(event.type.description.label)")
                    .font(.body(14, .bold))
                
                Image(systemName: "info.circle")
                    .font(.body(8, .medium))
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                    .offset(y: -3)
            }
            .padding(6)
            .padding(.leading, 2)
            .padding(.trailing, 2)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: 110, alignment: .trailing)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    
    
    @ViewBuilder
    private var timeView: some View {
        if let selectedDay {
            DropDownView(opensAbove: true, verticalOffset: 36, showOptions: $showTimePopup) {
                timeRow(selectedDay: selectedDay)
            } dropDown: {
                SelectTimeView(proposedTimes: $vm.respondDraft.newTime.proposedTimes, type: vm.respondDraft.originalInvite.event.type, showTimePopup: $showTimePopup)
            }
            .frame(height: 0)
        }
    }

    private func timeRow(selectedDay: Date) -> some View {
        VStack {
            originalTimeRow(selectedDay: selectedDay)
        }
    }
    
    private func originalTimeRow(selectedDay: Date) -> some View {
        HStack(alignment: .center, spacing: 5) {
            Image("MiniClockIcon")

            VStack(alignment: .leading) {
                Text(FormatEvent.dayAndTime(selectedDay))
                    .font(.body(17, .medium))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .offset(y: 0.5)
                
                
                if vm.respondDraft.respondMessage?.isEmpty ?? true {
                    if let message = vm.respondDraft.originalInvite.event.message {
                        eventMessageSection(message: message)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            DropDownChevron(showTimePopup: $showTimePopup)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private func eventMessageSection(message: String) -> some View {
        Button {
            showMessageScreen.toggle()
        } label: {
            (
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
                + Text("  Respond")
                    .font(.body(12, .bold))
                    .foregroundStyle(showMessageScreen ? Color.grayPlaceholder : (vm.responseType == .modified ? .accent : .appGreen))
            )
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    
    private var placeRow: some View {
        HStack(spacing: 12) {
            Image("MiniMapIcon")
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.location.name ?? "")
                        .font(.body(17, .medium))
                        .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))

                    Text(FormatEvent.addressWithoutCountry(event.location.address))
                            .font(.body(12, .medium))
                            .underline()
                            .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .lineLimit(1)
                }
        }
     }
    
    private func address() -> String {
        String([event.location.name, event.location.address]
                .compactMap { $0 }
                .joined(separator: ", ")
                .prefix(40)
        )
    }    
}


struct QuickInviteTime: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}


/*
 VStack(alignment: .leading, spacing: 6) {

 }
 Text(address())
     .font(.body(14, .regular))
     .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
     .underline()
     .lineLimit(1)
     .offset(y: 0.5)

 */
