//
//  InviteTypeRow.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

private let chevronSpacing: CGFloat = 9
private let rowHeight: CGFloat = 33



struct InviteTypeRow: View {
    
    //Injected Data to updated
    @Binding var eventType: Event.EventType
    @Binding var message: String?
    
    //Injected UI updating
    @Binding var showMessageScreen: Bool
    @Binding var showTypeDropDown: Bool
    
    //Hide the row when timeDropDown is open
    let timeDropDownOpen: Bool
    
    //Store which 'info' icons for the selectTypeDowndown open
    @State private var openInfoTypes: Set<Event.EventType> = []
    
    
    var body: some View {
        
        HStack {
            RowCaption(label: .what)
            Spacer(minLength: 12)
            
            HStack(alignment: .top, spacing: chevronSpacing) {
                VStack(spacing: 6) {
                    EventRowText(text: eventType.longTitle)
                    if let message { eventMessage(text: message)  }
                }
                DropDownButton(isOpen: showTypeDropDown)
            }
        }
    }
    
    private func eventMessage(text: String) -> some View {
        Text(text)
            .font(.body(14, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var typeMenu: some View {
        DropdownCustomMenu(
            isOpen: $showTypeDropDown,
            showMessageScreen: $showMessageScreen,
            message: message ?? "",
            onClose: { openInfoTypes.removeAll() },
            content: { selectTypeView },
            label:   { rowLabel }
        )
    }
    
    //The type view I open up
    private var selectTypeView: some View {
        SelectTypeView(
            openTypes: $openInfoTypes,
            selectedType: $eventType,
            showMessageScreen: $showMessageScreen,
            message: message ?? ""
        )
    }
}



struct InviteTimeRow: View {
    
    //Injected data updating
    @Binding var proposedTimes: ProposedTimes
    
    //If time is open
    @Binding var timeisOpen: Bool
    let typePopUpOpen: Bool
    
    let menuWidth: CGFloat = 325
    
    var body: some View {
        
        HStack {
            RowCaption(label: .what)
            Spacer(minLength: 12)
            TimeCustomMenu(estimatedContentSize: CGSize(width: menuWidth, height: 286), verticalPlacement: .below, isOpen: $timeisOpen){
                SelectTimeView(proposedTimes: $proposedTimes)
            } label: {
                rowLabel
            }
        }
        .blurPop(visible: !typePopUpOpen)
    }
    
    private var rowLabel: some View {
        HStack(spacing: chevronSpacing) {
            if proposedTimes.dates.isEmpty {
                EventRowPlaceholder(text: "Choose Time")
            } else {
                EventRowText(text: proposedTimes.formatMultipleInvitedDays())
            }
            DropDownButton(isOpen: timeisOpen == true)
        }
    }
}




struct InvitePlaceRow: View {
    
    let popupOpen: Bool
    @Binding var location: EventLocation?
    @Binding var showMapView: Bool
    
    var body: some View {
        
        HStack {
            RowCaption(label: .where)
            Spacer()
            HStack(spacing: chevronSpacing) {
                VStack(alignment: .trailing, spacing: 6) {
                    EventRowText(text: location.name ?? "The Venue")
                    Text(FormatEvent.addressBeforeFirstComma(location.address))
                        .font(.body(12, .regular))
                        .foregroundStyle(Color.textPlaceholder)
                        .lineLimit(1)
                }
                
                DropDownButton(isOpen: false)
            }
            .shrinkPress { showMapView = true }
        }
        .blurPop(visible: !popupOpen, scale: 1)
    }
}



//Generic Components
struct EventRowPlaceholder: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body(16, .regular))
            .foregroundStyle(Color.textSecondary)
            .kerning(text == "Choose Time" ? 0.32 : 0)
    }
}


struct EventRowText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.body(17, .medium))
            .foregroundStyle(Color.textPrimary)
            .lineLimitAndShrink(1)//Useful for times
    }
}

struct RowCaption: View {
    enum Label: String { case what, when, `where` }

    let label: Label
    
    var body: some View {
        Text(label.rawValue.capitalized)
            .font(.body(13, .medium))
            .foregroundStyle(Color.textTertiary)
    }
}

struct DropDownButton: View {
    let isOpen: Bool
    
    var body: some View {
        Image("DropdownGray")
            .rotationEffect(.degrees(isOpen ? 90 : 0))
            .animation(.toggle, value: isOpen)
    }
}
