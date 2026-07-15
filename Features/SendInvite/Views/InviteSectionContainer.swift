//
//  InviteSectionContainer.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

//Edit ⇄ Confirm is one card morphing in place, not two screens swapping. The pill and the
//card frame are persistent; only the content between them crossfades. Both content bodies stay
//mounted so their heights are known before the toggle — the card can then tween between them and
//clip the outgoing one, instead of sliding two transparent layouts past each other.
struct InviteSectionContainer: View {

    //Local view state
    @State private var ui = TimeAndPlaceUIState()
    @State private var showConfirmScreen = false
    @State private var showMessageScreen = false
    @State private var rowsHeight: CGFloat = 0     //ideal height of the edit rows
    @State private var confirmHeight: CGFloat = 0  //ideal height of the confirm summary

    //Injected
    let name: String
    let defaults: DefaultsManaging

    @Binding var draft: EventFieldsDraft
    @Binding var invitePopupOpen: Bool

    let onSendInvite: () -> ()

    //The pill recedes to grey while a picker is open — only meaningful on the edit side.
    private var popupDim: Bool { !showConfirmScreen && ui.isPopupOpenDelayed() }

    var body: some View {
        VStack(spacing: 0) {
            morphingContent
            sendButton
        }
        .sheet(isPresented: $showMessageScreen) { addMessageView }
        .animation(.expand, value: showConfirmScreen)
    }
}

//The morph: two bodies stacked, both measured, crossfading over an animating height
extension InviteSectionContainer {

    //Both bodies are always present (the hidden one at opacity 0), so the card knows both heights
    //up front and tweens cleanly between them. The taller body is clipped, never shown through.
    private var morphingContent: some View {
        ZStack(alignment: .top) {
            selectRows
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowsHeight = $0 }
                .opacity(showConfirmScreen ? 0 : 1)
                .blur(radius: showConfirmScreen ? Self.crossfadeBlur : 0)
                .allowsHitTesting(!showConfirmScreen)

            confirmScreen
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { confirmHeight = $0 }
                .opacity(showConfirmScreen ? 1 : 0)
                .blur(radius: showConfirmScreen ? 0 : Self.crossfadeBlur)
                .allowsHitTesting(showConfirmScreen)
        }
        .frame(height: contentHeight, alignment: .top)
        .clipped()
    }

    //nil until first measured, so the card opens at its natural height instead of snapping from 0.
    private var contentHeight: CGFloat? {
        let height = showConfirmScreen ? confirmHeight : rowsHeight
        return height > 0 ? height : nil
    }

    private static let crossfadeBlur: CGFloat = 6
}

//The one persistent pill: label, tint and action morph across the two states
extension InviteSectionContainer {

    private var sendButton: some View {
        let interactive = showConfirmScreen || draft.isComplete
        let tint: Color = popupDim || !interactive ? .fillGray : .textAccent

        return ScoopButton(
            style: .tinted(tint, shadow: showConfirmScreen ? .button : nil),
            shape: Capsule(),
            action: buttonTapped
        ) {
            Text(showConfirmScreen ? "Confirm & Send" : "Invite \(name)")
                .font(.body(18, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .contentTransition(.opacity) //label crossfades in place instead of hard-cutting
        }
        .opacity(popupDim ? 0.4 : 1)
        .allowsHitTesting(interactive)
        .padding(.top, showConfirmScreen ? Spacing.md : Spacing.xxs)
        .padding(.horizontal, Spacing.margin)
        .animation(.smooth, value: popupDim)
    }

    private func buttonTapped() {
        if showConfirmScreen {
            onSendInvite()
        } else {
            showConfirmScreen = true
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
            showConfirmScreen: $showConfirmScreen
        )
    }

    private var addMessageView: some View {
        NavigationStack { //NavStack added for navigationTitle -> stack don't persist in sheets
            AddMessageView(message: $draft.message, isRespondMessage: false, eventType: $draft.type)
        }
    }
}
