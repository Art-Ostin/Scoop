//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardInfo: View {
    
    let image: UIImage?
    let name: String
    
    let event: UserEvent
    
    @State var selectedDay: Date?
    
    @State var newProposedDates: [Date]? = nil
    @State var showProposeDate: Bool = false
    
    var isPopup: Bool {
        image != nil
    }
 
    @State var showTimePopup: Bool = false
    
    @Bindable var vm: RespondViewModel

    init(vm: RespondViewModel, image: UIImage?, name: String, event: UserEvent) {
        self.image = image
        self.name = name
        self.event = event
        self.vm = vm
        self._selectedDay = State(initialValue: event.proposedTimes.firstAvailableDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            title
            timeView
            placeRow
            responseRow
        }
        .padding(.horizontal, 16)
    }
}

extension InviteCardInfo {
    
    private var responseRow: some View {
        HStack {
            DeclineButton(vm: vm)
            Spacer()
            AcceptButton(vm: vm)
        }
    }
    
    private var title: some View {
        HStack(alignment: .top, spacing: 12) {
            if let image {
                CirclePhoto(image: image)
            }
            
            Text("\(name)'s Invite")
                .font(.body(20, .bold))
            
            Spacer()
            
            HStack {
                Text("\(event.type.description.emoji)  \(event.type.description.label)")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
            }
        }
    }
    
    
    @ViewBuilder
    private var timeView: some View {
        if let selectedDay {
            DropDownView(opensAbove: true, showOptions: $showTimePopup) {
                timeRow(selectedDay: selectedDay)
            } dropDown: {
                SelectAvailableDay(event: event, selectedDay: $selectedDay, showTimePopup: $showTimePopup)
            }
            .frame(height: 0)
        }
    }

    private func timeRow(selectedDay: Date) -> some View {
        HStack(alignment: .center, spacing: 9) {
            Image("MiniClockIcon")
            
            HStack {
                Text(EventFormatting.fullDateAndTime(selectedDay))
                    .font(.body(16, .regular))
                    .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .offset(y: 0.5)
            }
            Spacer()
            DropDownButton(isExpanded: $showTimePopup, isAccept: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var placeRow: some View {
        HStack(spacing: 12) {
            Image("MiniMapIcon")
            
            Text(address())
                .font(.body(14, .regular))
                .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
                .underline()
                .lineLimit(1)
                .offset(y: 0.5)
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
