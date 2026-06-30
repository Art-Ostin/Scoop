//
//  ConfirmInviteScreen.swift
//  Scoop Test
//
//  Created by Art Ostin on 29/06/2026.
//

import SwiftUI

struct ConfirmInviteScreen: View {
    let draft: EventFieldsDraft
    let name: String
    let defaults: DefaultsManaging
    @Binding var showConfirmInviteScreen: Bool
    
    @State var scrollPosition: Int? = 0
    private var isShowingEvent: Bool { scrollPosition == 0 }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
                .padding(.horizontal, 30)
            contentScrollView
            warningText
                .padding(.horizontal, 30)
            actionSection
                .padding(.horizontal, 20)
        }
        .overlay(alignment: .topTrailing) {
            messageButton
                .padding(.trailing, 30)
        }
            .modifier(ConfirmInviteBackground())
    }
}

//Title Section
extension ConfirmInviteScreen {
    private var title: some View {
        Text("Meet \(name)")
            .font(.body(20, .bold))
    }
    
    private var messageButton: some View {
        HStack(spacing: 4) {
            
            if scrollPosition == 1 {
                Image(systemName: "chevron.left")
                    .font(.body(8, .bold))
            }
            
            Text(scrollPosition == 0 ? "Message" : "Event")
                .font(.body(10, .bold))
                .kerning(1)
            
            if scrollPosition == 0 {
                Image(systemName: "chevron.right")
                    .font(.body(8, .bold))
            }
        }
        .padding(8)
        .padding(.leading, 2)//Bit Extra Padding
        .overlay {
            Capsule()
                .strokeBorder(Color(white: 0.8), lineWidth: 1)
        }
        .shrinkPress {
            withAnimation(.snappy) {
                scrollPosition = isShowingEvent ? 1 : 0
            }
        }
        .transition(.blurReplace)
        .clipped()
        .offset(y: -4)
    }
}


extension ConfirmInviteScreen {
    
    private var contentScrollView: some View {
        ScrollView(.horizontal) {
            HStack {
                eventInfoText
                    .padding(.horizontal, 30)
                    .containerRelativeFrame(.horizontal, alignment: .leading)
                    .id(0)
                
                messageText
                    .padding(.horizontal, 30)
                    .containerRelativeFrame(.horizontal, alignment: .leading)
                    .id(1)
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPosition)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .customHorizontalScrollFade(width: 40, showFade: true, fromLeading: true, isCardInvite: false)
        .customHorizontalScrollFade(width: 40, showFade: true, fromLeading: false, isCardInvite: false)
    }
    
    
    @ViewBuilder
    private var messageText: some View {
        if let message = draft.message {
            Text(message)
                .font(.system(size: 13, weight: .regular).italic())
                .foregroundStyle(Color(red: 0.43, green: 0.43, blue: 0.45))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
    }
}

//Where and Where Text
extension ConfirmInviteScreen {
    
    private var eventInfoText: some View {
        VStack(alignment: .leading, spacing: 6) {
            whatAndWhereText
            timeView
        }
    }
    
    
    private var whatAndWhereText: some View {
        let whatText = draft.type.longTitle
        let whereText = draft.place?.name ?? "Venue Here"
        
        return HStack(spacing: 8 ) {
            Text(whatText)
                .foregroundStyle(Color(white: 0.14))
                .layoutPriority(1)
            Text("·")
                .layoutPriority(1)
                .foregroundStyle(Color(white: 0.14))
            
            Text(whereText)
                .foregroundStyle(.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shrinkPress {
                    MapsRouter.openMaps(defaults: defaults, item: draft.place?.mapItem, withDirections: false)
                }
        }
        .font(.body(16, .medium))
    }
    
    private var timeView: some View {
        let dates = draft.time.dates.map(\.date)
        return Group {
            switch dates.count {
            case 1:    Text(FormatEvent.dayAndTime(dates[0])).font(.body(16, .medium))
            case 2, 3: multipleDaysView(dates: dates)   // derives isThreeDays = dates.count == 3 internally
            default:   EmptyView()
            }
        }
        .lineLimit(1)
        .foregroundStyle(Color(white: 0.14))
    }
    
    private func multipleDaysView(dates: [Date]) -> some View {
        let isThreeDays = dates.count == 3
       return HStack(spacing: isThreeDays ? 4 : 8) {
            ForEach(dates, id: \.self) { date in
                Text(FormatEvent.shortDayAndTime(date, withHour: false))
                    .font(.body(isThreeDays ? 14 : 16, .medium))
                    .foregroundStyle(Color(white: 0.14))
                
                if date != dates.last {
                    Text("or")
                        .font(.body(12, .regular))
                        .foregroundStyle(Color(white: 0.7))
                }
            }
            
            if !isThreeDays {
                Text("·")
                
                if let date = dates.first {
                    Text(FormatEvent.hourTime(date))
                        .font(.body(16, .medium))
                        .foregroundStyle(Color(white: 0.14))
                }
            }
        }
    }
}


//ActionSection
extension ConfirmInviteScreen {
    
    private var warningText: some View {
        Text("If they accept a time and I don’t show I understand I’ll be blocked from Scoop")
            .foregroundColor(Color(red: 0.66, green: 0.66, blue: 0.7))
            .multilineTextAlignment(.leading)
            .font(.body(12, .regular))
            .lineSpacing(4)
    }
    
    private var actionSection: some View {
        HStack(spacing: 18) {
            cancelButton
            sendButton
        }
        .padding(.horizontal, -10)
    }
    
    var cancelButton: some View {
        Text("Cancel")
            .font(.body(17, .bold))
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.9), in: Capsule())
            .shrinkPress { showConfirmInviteScreen = false }
    }
    
    var sendButton: some View {
        Text("Confirm & Send")
            .font(.body(17, .bold))
            .foregroundStyle(Color.white)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Color.accent, in: Capsule())
            .shrinkPress { print("Logic to Send Invite Here") }
    }
}

struct ConfirmInviteBackground: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding(.top, 26)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(Color.appCanvas, in: .rect(cornerRadius: 36))
            .padding(.horizontal, 30)
    }
}
