//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {

    @Bindable var ui: TimeAndPlaceUIState
    
    @Binding var type: Event.EventType
    @Binding var unparsedMessage: String?
    
    @State private var messageHeight: CGFloat = 0
    
    //The message we last derived a line count from. Lets us ignore height re-measures caused by
    //the margin animation re-wrapping the same text, so the line count (and margin) can't oscillate.
    @State private var lastCountedMessage = ""
    
    
    //Chooses which sections info is open, controlled here as need to update
    @State private var openInfoTypes: Set<Event.EventType> = []

    //Choose corner radius for different drop down menus
    private let menuCorners = RectangleCornerRadii(top: 16, bottom: 6)
    private let footerCorners = RectangleCornerRadii(top: 6, bottom: 14)

    var message: String  {
        (unparsedMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }


    var body: some View {
            HStack {
                inviteTypeText(.what)
                Spacer(minLength: 16)
                inviteTypeButton
            }
    }
}

//With Message Views
extension InviteTypeRow {
    
    @ViewBuilder
    private var inviteTypeButton: some View {
        CustomMenu(
            cornerRadii: menuCorners,
            footerCornerRadii: footerCorners,
            keepsLabel: true, //title + chevron stay put; the glass just blooms out from over them
            onOpen: { ui.popupOpen = true },
            onClose: { ui.popupOpen = false ; openInfoTypes.removeAll()   },
            footer: { AnyView(AddMessageFooter(message: message,
                                               showMessageScreen: $ui.showMessageScreen,
                                               cardCorners: footerCorners)) }
        ) {
            selectTypeView //detached "Add a Message" card now lives in the footer below
        } label: {
            inviteTypeIcon
        }
    }
    
    private var inviteTypeIcon: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing) {
                
                Text(type.longTitle) //type.emoji + " " + Removed the Emoji
                    .font(.body(17, .medium))
                    .contentTransition(.opacity)
                    .geometryGroup() //Fixes for clear transition
                
                if !message.isEmpty {
                    inviteMessage
                }
            }
            Image("InviteChevron")
        }
        .task(id: messageHeight) { updateLineHeight() }       //typing: recount once the new text's height settles
        .onChange(of: message) { _, _ in updateLineHeight() } //clearing/edits: recount (and reset) on text change
    }
    
    
    private var inviteMessage: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.gray)
            .lineLimit(3)
            .multilineTextAlignment(.trailing)
        
            .onGeometryChange(for: CGFloat.self) { geo in
                geo.size.height
            } action: { newValue in
                messageHeight = newValue
            }
            .transition(.opacity.animation(.smooth(duration: 0.2)))
    }
    
    
    private var selectTypeView: some View {
        SelectTypeView(
            openTypes: $openInfoTypes,
            selectedType: $type,
            showMessageScreen: $ui.showMessageScreen,
            showTypePopup: ui.binding(for: .type),
            message: message,
            cardCorners: menuCorners
        )
    }
    
    private func updateLineHeight() {
        //1. No message (incl. clear): reset the count, and the dedupe key so the next message recounts.
        if message.isEmpty {
            ui.messageLineCount = 0
            lastCountedMessage = ""
            return
        }
        guard message != lastCountedMessage, messageHeight > 0 else { return }

        let lineHeight = UIFont.preferredFont(forTextStyle: .footnote).lineHeight
        ui.messageLineCount = min(3, Int((messageHeight / lineHeight).rounded()))
        lastCountedMessage = message
    }

}


//The detached "Add a Message" card, rendered as CustomMenu's footer. It is its own
//View (not a computed property of InviteTypeRow) on purpose: it reads
//`customMenuDismiss` from where it actually renders — INSIDE the menu overlay — so the
//tap closes the menu and then opens the sheet. Read on InviteTypeRow that environment
//resolves to the main tree and is a no-op.
private struct AddMessageFooter: View {

    @Environment(\.customMenuDismiss) private var menuDismiss

    let message: String
    @Binding var showMessageScreen: Bool
    //Mirror of the platter's corners: tight (10) on the edge facing the menu, round
    //(16) on the bottom — so the stroke matches the footer's own glass shape.
    let cardCorners: RectangleCornerRadii

    var body: some View {
        Text(message.isEmpty ? "Add a Message" : "Edit Message")
            .foregroundStyle(Color.black)
            .font(.body(16, .bold))
            .kerning(0.5)
            .frame(height: 40)
            .modifier(SelectTypeCardBackground(corners: cardCorners)) //same stroked card as the type list
            .customMenuFooterPlatter(corners: cardCorners) //own the glass platter so the press scales it, not just the inside
            .contentShape(.rect)
            .shrinkPress { //now wraps the platter → the whole container shrinks on press
                menuDismiss()
                showMessageScreen = true
            }
    }
}

/*
 
 Button {
     ui.showMessageScreen.toggle()
 } label: {
     Text(message.isEmpty ? "Add a Message" : "Edit Message")
         .foregroundStyle(Color.black)
         .font(.body(16, .bold))
         .kerning(0.5)
         .frame(height: 40)
         .modifier(SelectTypeCardBackground()) //Same background as select Type
         .shrinkPress()
 }
 */
