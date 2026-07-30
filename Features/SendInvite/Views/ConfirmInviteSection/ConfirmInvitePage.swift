//
//  ConfirmInviteScreen.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

enum ConfirmMode {
    case Invite, Respond
}

struct ConfirmInvitePage<TimeRow: View>: View {
    
    let event: InviteSummary
    let name: String
    
    
    @Binding var showMessageScreen: Bool
    
    @ViewBuilder var timeRow: TimeRow
    
    //Local Properties
    @State private var showInfoSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InviteName(name: name, isPopup: false)
            ConfirmInviteScrollView(invite: event,showMessageScreen: $showMessageScreen) {
                timeRow
            }
            WarningLabel()
        }
        .invitePageChrome(type: event.type, showInfoSheet: $showInfoSheet)
    }
}

extension View {
        func invitePageChrome(type: Event.EventType, showInfoSheet: Binding<Bool>) -> some View {
            self
                .padding(.horizontal, Spacing.margin)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .topTrailing) { InviteTypeButton(type: type, showInfoSheet: showInfoSheet) }
                .padding(.top, 20)
                .sheet(isPresented: showInfoSheet) { Text(type.title).presentationDetents([.medium]) }
        }
}
