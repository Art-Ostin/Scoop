//
//  InviteSectionContainer.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

//Edit ⇄ Confirm is one card morphing in place, not two screens swapping. The pill and the
//card frame are persistent; only the content between them slides. Both content bodies stay
//mounted so their heights are known before the toggle — the card can tween its height while the
//content slides within the clipped card bounds.
struct InviteSectionContainer: View {

    //Local view state
    @State private var ui = TimeAndPlaceUIState()
    @State private var showMessageScreen = false
    @State private var rowsHeight: CGFloat = 0     //ideal height of the edit rows
    @State private var confirmHeight: CGFloat = 0  //ideal height of the confirm summary
    @State private var contentWidth: CGFloat = 0   //slide distance between the edit and confirm screens

    //Injected
    let name: String
    let defaults: DefaultsManaging

    @Binding var draft: EventFieldsDraft
    @Binding var invitePopupOpen: Bool
    @Binding var confirmInviteScreen: Bool

    let onSendInvite: () -> ()

    //The pill recedes to grey while a picker is open — only meaningful on the edit side.
    private var popupDim: Bool { !confirmInviteScreen && ui.isPopupOpenDelayed() }

    var body: some View {
        VStack(spacing: 0) {
            morphingContent
            sendButton
        }
        .sheet(isPresented: $showMessageScreen) { addMessageView }
    }
}

//The morph: two bodies stacked, both measured, sliding over an animating height
extension InviteSectionContainer {

    //Both bodies are always present, so the card knows both heights up front and tweens cleanly
    //between them. The inactive body sits just outside the clipped content bounds.
    private var morphingContent: some View {
        ZStack(alignment: .top) {
            selectRows
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowsHeight = $0 }
                .offset(x: confirmInviteScreen ? -contentWidth : 0)
                .allowsHitTesting(!confirmInviteScreen)

            confirmScreen
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { confirmHeight = $0 }
                .offset(x: confirmInviteScreen ? 0 : contentWidth)
                .opacity(contentWidth > 0 ? 1 : 0)
                .allowsHitTesting(confirmInviteScreen)
        }
        .frame(height: contentHeight, alignment: .top)
        .clipped()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
    }

    //nil until first measured, so the card opens at its natural height instead of snapping from 0.
    private var contentHeight: CGFloat? {
        let height = confirmInviteScreen ? confirmHeight : rowsHeight
        return height > 0 ? height : nil
    }
}

//The one persistent pill: label, tint and action morph across the two states
extension InviteSectionContainer {

    private var sendButton: some View {
        let interactive = confirmInviteScreen || draft.isComplete
        let tint: Color = popupDim || !interactive ? .fillGray : .textAccent

        return ScoopButton(
            style: .tinted(tint, shadow: nil),
            shape: Capsule(),
            action: buttonTapped
        ) {
            Text(confirmInviteScreen ? "Confirm & Send" : "Invite \(name)")
                .font(.body(18, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .contentTransition(.opacity) //label crossfades in place instead of hard-cutting
        }
        .opacity(popupDim ? 0.4 : 1)
        .allowsHitTesting(interactive)
        .padding(.top, confirmInviteScreen ? Spacing.md : Spacing.xxs)
        .padding(.horizontal, Spacing.margin)
        .animation(.smooth, value: popupDim)
    }

    private func buttonTapped() {
        if confirmInviteScreen {
            onSendInvite()
        } else {
            confirmInviteScreen = true
        }
    }
}

//Sub-screens & sheets
extension InviteSectionContainer {

    private var selectRows: some View {
        SelectTimeAndPlace(
            ui: ui,
            draft: $draft,
            showMessageScreen: $showMessageScreen,
            defaults: defaults,
            onPopupOpenChange: { invitePopupOpen = $0 }
        )
    }

    private var confirmScreen: some View {
        ConfirmInviteScreen(
            name: name,
            event: $draft,
            showConfirmScreen: $confirmInviteScreen
        )
    }

    private var addMessageView: some View {
        NavigationStack { //NavStack added for navigationTitle -> stack don't persist in sheets
            AddMessageView(message: $draft.message, isRespondMessage: false, eventType: $draft.type)
        }
    }
}
