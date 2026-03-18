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
    
    var isPopup: Bool {
        image != nil
    }
 
    @State var showTimeDropDown: Bool = false
    
    @Bindable var vm: RespondViewModel
    
    var selectedDay: Date? {
        event.proposedTimes.firstAvailableDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            title
            time
            place
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
                Text("\(event.type.description.emoji ?? "")  \(event.type.description.label)")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
            }
        }
    }
    
    @ViewBuilder
    private var time: some View {
        if let firstAvailableDate = event.proposedTimes.firstAvailableDate {
            DropDownView(showOptions: $showTimeDropDown) {
                timeRow(firstAvailableDate: firstAvailableDate)
            } dropDown: {
                typeDropDown
            }
            .frame(height: 0)
        }
    }


    private func timeRow(firstAvailableDate: Date) -> some View {
        HStack(alignment: .center, spacing: 9) {
            Image("MiniClockIcon")
            
            HStack {
                Text(EventFormatting.fullDateAndTime(firstAvailableDate))
                    .font(.body(16, .regular))
                    .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .offset(y: 0.5)
            }
            Spacer()
            DropDownButton(isExpanded: $showTimeDropDown, isAccept: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var place: some View {
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
        String(
            [event.location.name, event.location.address]
                .compactMap { $0 }
                .joined(separator: ", ")
                .prefix(50)
        )
    }
    
    
    @ViewBuilder
    private var typeDropDown: some View {
        DropDownMenu {
            ForEach(event.proposedTimes.availableDates(), id: \.self) { date in
                let isSelected = selectedDay == date
                let formattedDate = EventFormatting.expandedDate(date)

                DropDownRow(text: formattedDate, isSelected: isSelected, isLastRow: false) {
                    
                }
            }
        }
    }
    
    @ViewBuilder
    private func dropDownRow(date: Date) -> some View {
        let isSelected = selectedDay == date
        let formattedDate = EventFormatting.expandedDate(date)

        DropDownRow(text: formattedDate, isSelected: isSelected, isLastRow: false) {
            se
            showTimeDropDown = false
        }
    }
}
