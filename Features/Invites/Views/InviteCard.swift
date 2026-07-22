//
//  NewInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI
import Glur


struct InviteCard: View {
    
    //Injected Parameters
    let image: UIImage
    let name: String
    
    @Binding var draft: RespondDraft
    @Binding var openInvite: Bool
    
    //Local Parameters
    @State private var timePopupOpen = false
    @State private var timePopupPage: TimePopupPage? = .newTime //Must stay at this level
    
    var body: some View {
        ScoopImage(image: image, aspectRatio: .inviteCard)
            .modifier(BlurAndGradientBackground())
            .overlay(alignment: .bottom) {overlayText}
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, -16)
    }
}

//Title And Type
extension InviteCard {
    
    private var overlayText: some View {
        VStack(alignment: .leading, spacing: 24) {
            nameTitle
                .opacityPop(visible: !timePopupOpen)
            timeMenu
            placeRow
                .opacityPop(visible: !timePopupOpen)
        }
        .overlay(alignment: .topTrailing) { typeButton}
        .frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .bottomLeading)
        .overlay(alignment: .bottomTrailing) {inviteButton}
        .padding(24)
        .padding(.bottom, 5)
    }    
    
    private var nameTitle: some View {
        Text(name)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var typeButton: some View {
            HStack {
                Image("DrinkIcon")
                
                Text(draft.originalInvite.event.type.longTitle) //"Grab Drinks"
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .stroke(12, lineWidth: 1, color: .white.opacity(0.6))
            .scaleEffect(0.8, anchor: .bottomTrailing)
            .offset(y: -1.5)
            .opacityPop(visible: !timePopupOpen)
    }
    
    private var inviteButton: some View {
        Image("LetterIconProfile")
            .scaleEffect(0.8)
            .frame(width: 40, height: 40)
            .background(Color(red: 0, green: 0.4, blue: 0.43), in: Circle())
            .shrinkPress {openInvite = true}
            .opacityPop(visible: !timePopupOpen)
    }
}


//Time And Place
extension InviteCard {
    
    
    private var timeMenu: some View {
        TimeCustomMenu(cornerRadius: CornerRadius.customMenu,
                       tracksContentSizeChanges: true,
                       placementOffsetX: 0,
                       placementOffsetY: 24,
                       isOpen: $timePopupOpen,
                       onOpen: { timePopupPage = .invitedTimes }) {
            timePopupContainer
        } label: {
            timeRow
        }
    }
    
    private var timePopupContainer: some View {
        TimePopupContainer(
            respondType: $draft.respondType,
            selectedDay: $draft.originalInvite.selectedDay,
            newProposedTimes: $draft.newTime.proposedTimes,
            page: $timePopupPage,
            times: draft.originalInvite.event.proposedTimes
        )
    }
    
    // Logic with the time
    private var timeRow: some View {
        HStack {
            lineSection(image: "WhiteClock", text: timeText).padding(.top, -1)
            timeChevron
        }
        .oneLineLimitAndShrink()
    }
    
    private var timeChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.white)
            .rotationEffect(.degrees(timePopupOpen ? 90 : 0))
            .animation(.toggle, value: timePopupOpen)
    }
    
    private var timeText: String {
                
        if draft.respondType == .original {
            if let time = draft.originalInvite.selectedDay {
                return FormatEvent.shortDayAndTime(time)
            } else {
                return "Choose Time"
            }
        } else if draft.respondType == .modified {
           return draft.newTime.proposedTimes.formatMultipleInvitedDays()
        } else {
            return ""
        }
    }
    
    //Logic with the place
    private var placeRow: some View {
        let place = draft.originalInvite.event.location
        return lineSection(image: "WhiteMap", text: place.name ?? place.address ?? "Location")
            .shrinkPress { MapsRouter.openGoogleMaps(item: place.mapItem)}
    }
    
    private func lineSection(image: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(image)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}



struct BlurAndGradientBackground: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .glur(
                radius: 24,
                offset: 0.7,
                interpolation: 0.34,
                direction: .down,
                noise: 0
            )
            .overlay { blackGradient }
            .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image)))
    }
    
    private var blackGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0), location: 0.65),
                .init(color: .black.opacity(0.6), location: 0.8),
                .init(color: .black.opacity(0.7), location: 0.85),
                .init(color: .black.opacity(0.9), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

extension View {
    func oneLineLimitAndShrink() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
    }
}
