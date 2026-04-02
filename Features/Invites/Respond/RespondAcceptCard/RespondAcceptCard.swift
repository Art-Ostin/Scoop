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
        vm.respondDraft.newTime.message?.isEmpty == false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            RespondTitle(isFlipped: $isFlipped, showTimePopup: showTimePopup, event: event, image: vm.image)
            VStack(alignment: .leading, spacing: showMessageRow ? 0 : 20) {
                RespondTimeRow(vm: vm, showTimePopup: $showTimePopup, showMessageScreen: $showMessageScreen)
                respondMessagesView
                placeRow
            }
            .zIndex(3)
            actionSection
                .zIndex(1)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(customBackground)
        .padding(.horizontal, showMessageRow ? 16 : 24)
        .offset(y: 24)
        .animation(.easeInOut(duration: 0.2), value: showTimePopup)
        .animation(.easeInOut(duration: 0.2), value: vm.respondDraft.respondType)
        .sheet(isPresented: $showMessageScreen) {
            AddMessageView(eventType: $vm.respondDraft.newTime.event.type, showMessageScreen: $showMessageScreen, message: $vm.respondDraft.newTime.message, isRespondMessage: true)
        }
        .onChange(of: vm.responseType, { oldValue, newValue in
            print("Old value is: \(oldValue)")
            print("New value is: \(newValue)")
        })
    }
}

extension RespondAcceptCard {
    @ViewBuilder
    private var respondMessagesView: some View {
        if vm.responseType != .original {
            if let originalMessage = vm.respondDraft.event.message, let newMessage = vm.respondDraft.newTime.message {
                RespondMessagesView(showTimePopup: showTimePopup, originalMessage: originalMessage, replyMessage: newMessage, showMessageScreen: $showMessageScreen)
            }
        }
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
 VStack(alignment: .leading, spacing: showMessageRow ? 20 : 24) {
     titleAndTime
         .zIndex(3)
     placeRow
         .zIndex(1)
 }
 .zIndex(2) //Fixes bug so backdrop appears above.

 */


/*
 private var titleAndTime: some View {
     VStack(alignment: .leading, spacing: 20) {
         titleRow
             .opacity(showTimePopup ? 0.03 : 1)
         RespondTimeRow(vm: vm, showTimePopup: $showTimePopup, showMessageScreen: $showMessageScreen)
     }
 }

 */
