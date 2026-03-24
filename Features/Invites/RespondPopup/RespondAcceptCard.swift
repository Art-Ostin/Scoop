//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//
import SwiftUI

struct RespondAcceptCard: View {
    
    @Bindable var vm: RespondViewModel
    @Binding var isFlipped: Bool
    
    @State private var showTimePopup: Bool = false

    
    var event: UserEvent {
        vm.respondDraft.event
    }
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 20) { //Camera pushes it down more, this makes it more natural
                titleRow
                    .opacity(showTimePopup ? 0.3 : 1)
                
                RespondTimeRow(vm: vm, showTimePopup: $showTimePopup)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .zIndex(2) //Fixes bug so backdrop appears above.
            placeRow
            actionSection
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(CardBackground())
        .padding(.horizontal, 24)
        .offset(y: 24)
        .animation(.easeInOut(duration: 0.2), value: showTimePopup)
    }
}

extension RespondAcceptCard {
    
    private var titleRow: some View {
        HStack(spacing: 16) {
            eventTitle
            eventType
        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }
    
    private var eventTitle: some View {
        HStack(spacing: 8) {
            CirclePhoto(image: vm.image, showShadow: false, height: 30)
            Text("Meet \(event.otherUserName)")
                .font(.custom("SFProRounded-Bold", size: 24))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .layoutPriority(1)
    }
    
    private var eventType: some View {
        Button {
            isFlipped.toggle()
        } label: {
            HStack(spacing: 2) {
                Text("\(event.type.description.emoji) \(event.type.description.label)")
                    .font(.body(16, .medium))
                
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.grayText).opacity(0.8)
                    .font(.body(14, .medium))
                    .offset(y: -4)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: 110, alignment: .trailing)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var placeRow: some View {
        HStack(spacing: 24) {
            Image("MiniMapIcon")
                .scaleEffect(1.3)
                .foregroundStyle(Color.appGreen)
            
            VStack {
                let location = event.location
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(16, .medium))
                    Text(EventFormatting.addressWithoutCountry(location.address))
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .underline()
                        .lineLimit(1)
                }
            }
        }
    }

    private var actionSection: some View {
        HStack {
            DeclineButton {vm.onAccept() }
            Spacer()
            AcceptButton {vm.onDecline()}
        }
    }
}
