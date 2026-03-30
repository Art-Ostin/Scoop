//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//


//If its in modified mode -> 
import SwiftUI

struct RespondAcceptCard: View {
    
    @Bindable var vm: RespondViewModel
    @Binding var isFlipped: Bool
    
    @State private var showTimePopup: Bool = false
    @State private var showTypeMessageScreen: Bool = false
    @State private var showMessageScreen: Bool = false
    
    var event: UserEvent {
        vm.respondDraft.event
    }
    
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var showMessageRow: Bool {
        vm.respondDraft.respondType == .modified &&
        !(vm.respondDraft.newTime.message?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: showMessageRow ? 6 : 24) {
                titleAndTime
                messageRow
                placeRow
            }
            actionSection
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(customBackground)
        .padding(.horizontal, 24)
        .offset(y: 24)
        .animation(.easeInOut(duration: 0.2), value: showTimePopup)
        .animation(.easeInOut(duration: 0.2), value: vm.respondDraft.respondType)
        .sheet(isPresented: $showMessageScreen) {
            AddMessageView(eventType: $vm.respondDraft.newTime.event.type , showMessageScreen: $showMessageScreen, message: $vm.respondDraft.newTime.message, isRespondMessage: true)
        }
    }
}

extension RespondAcceptCard {
    
    private var titleRow: some View {
        HStack(spacing: 16) {
            eventTitle
            eventTypeButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var titleAndTime: some View {
        VStack(alignment: .leading, spacing: 20) {
            titleRow
                .opacity(showTimePopup ? 0.03 : 1)
            RespondTimeRow(vm: vm, showTimePopup: $showTimePopup, showMessageScreen: $showMessageScreen)
        }
        .zIndex(2) //Fixes bug so backdrop appears above.
    }
    
    @ViewBuilder
    private var messageRow: some View {
        if showMessageRow {
            RespondMessageSection(showMessageScreen: $showMessageScreen, showTimePopup: $showTimePopup, message: message)
        }
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
    
    private var eventTypeButton: some View {
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
                    Text(FormatEvent.addressWithoutCountry(location.address))
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
            DeclineButton {vm.decline()}
            Spacer()
            AcceptButton(isModified: vm.respondDraft.respondType != .original) { vm.accept()}
        }
    }
    
    private var customBackground: some View {
        ZStack { //Background done like this to fix bugs when popping up
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.background)
                .surfaceShadow(.card, strength: showTimePopup ? 0 : 1)
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
        }
    }
    
    
}




/*
 if vm.respondDraft.respondType == .modified  {
     if let message = event.message {
         RespondMessageRow(showTypeMessage: $showTypeMessageScreen, eventMessage: message)
     }
 }
 */

/*
 
 
 VStack(alignment: .leading, spacing: shortenSpacing ? 0 : 24) {
     VStack(alignment: .leading, spacing: 20) { //Camera pushes it down more, this makes it more natural
         titleRow
             .opacity(showTimePopup ? 0.03 : 1)
                         
         RespondTimeRow(vm: vm, showTimePopup: $showTimePopup, showMessageScreen: $showMessageScreen)
     }
     .frame(maxWidth: .infinity, alignment: .leading)
     .zIndex(2) //Fixes bug so backdrop appears above.
     placeRow
 }
 .zIndex(2) //Fixes bug so backdrop appears above.
 actionSection
}
 */
