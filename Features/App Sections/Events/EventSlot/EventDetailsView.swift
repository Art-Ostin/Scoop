//
//  EventTimeAndPlace.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct EventDetailsView: View {
    
    @Bindable var ui: EventUIState
    @Binding var selectedTab: Int
    
    let event: UserEvent
    
    var hasMessage: Bool { event.message?.isEmpty == false }
    
    var body: some View {
        VStack(alignment: .leading, spacing: hasMessage ? 24 : 28) {
            timeRow
            InviteCardPlaceRow(location: event.location, isMeetUp: true)
            detailRow
        }
        .measure(key: EventDetailsHeight.self) { geo in
            return geo.size.height
        }
    }
    
    private var detailRow: some View {
        Button {
                selectedTab = 2
        } label: {
            HStack(spacing: 18) {
                Text(event.type.description.emoji)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(event.type.longTitle)")
                        .overlay(alignment: .topTrailing) {
                            infoOverlay
                                .offset(y: -4)
                                .offset(x: 16)
                        }
                    Text(event.message ?? "")
                        .font(.footnote)
                        .foregroundStyle(Color.gray)
                        .layoutPriority(1)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.body(18, .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, -20)
        }
    }
    
    private var timeRow: some View{
        HStack(spacing: 22) {
            Image("Clock")
                .resizable()
                .frame(width: 20, height: 20)
                .offset(x: 1)
            
            if let acceptedTime =  event.acceptedTime {
                Text(FormatEvent.dayAndTime(acceptedTime, withHour:  true))
                    .font(.body(18, .medium))
            }
        }
    }
    
    private var infoOverlay: some View {
        Image(systemName: "info.circle")
            .font(.body(10, .medium))
            .foregroundStyle(Color(red: 0.75, green: 0.75, blue: 0.75))
    }
}

struct EventDetailsHeight: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
