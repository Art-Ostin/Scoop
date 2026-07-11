//
//  CantMakeIT.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct CantMakeIt: View {
    
    //Injected
    let vm: EventsViewModel
    let eventProfile: EventProfile

    //Local view state
    @State private var showCancelAlert: Bool = false

    private var fullTime: String {
        FormatEvent.dayAndTime(eventProfile.event.acceptedTime ?? Date())
    }

    private var hour: String {
        return eventProfile.event.acceptedTime?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) ?? "22"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg){
            Text("Can’t Make It?")
                .font(.body(24, .bold))
            
            Text("We get it, shit happens. You can cancel up to 10 hours before (No rescheduling).")
                             
            Text("But to deter people bailing from nerves or effort ")
            + Text("your account is frozen for 14 days 🥶")
                .foregroundStyle(Color.successGreen)
            
            
            Text("If you don’t show, ")
            + Text("your account is permanently blocked, ")
                .font(.body(16, .bold))
            
            + Text("so better to cancel if you must")
            
            Image("Monkey")
                .frame(width: 240, height: 240)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(spacing: Spacing.md) {
                Text("Meeting \(eventProfile.event.otherUserName)")
                
                Text("\(fullTime) · \(hour)")
            }
            .font(.body(18, .medium))
            .frame(maxWidth: .infinity)
            
            cancelButton
        }
        .font(.body(16, .medium))
        .lineSpacing(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, Spacing.lg)
        .padding(.horizontal, Spacing.margin)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .top, spacing: 0) {
            DismissButton(type: .cross)
            Spacer()
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxs)
        }
        .background(Color.appCanvas)
        .customAlert(isPresented: $showCancelAlert, title: "Cancel Date",message: "By clicking confirm you understand your account will be frozen for 2 weeks & all pending invites removed.", emoji: "🚨", cancelTitle: "Back", okTitle: "Confirm", showTwoButtons: true) {
            Task {
                do {
                    try await vm.cancelEvent(event: eventProfile.event)
                    vm.session.appState = .frozen
                } catch {
                    // TODO: route cancel failure to InAppNotificationCenter
                }
            }
        }
        .interactiveDismissDisabled(showCancelAlert)
    }
}

extension CantMakeIt {
    
    private var cancelButton: some View {
        Button {
            showCancelAlert.toggle()
        } label: {
            Text("Cancel Date")
                .frame(width: 120, height: 35)
                .stroke(CornerRadius.sm, lineWidth: 2, color: Color.dangerRed)
                .foregroundStyle(Color.dangerRed)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Spacing.lg)
        }
    }
    
}
