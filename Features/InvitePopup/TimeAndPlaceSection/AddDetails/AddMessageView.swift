//
//  InviteAddMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct AddMessageView: View {
    
    //Injected
    @Environment(\.dismiss) private var dismiss
    @Binding var message: String?
    let isRespondMessage: Bool
    var name: String? = nil
    @Binding var eventType: Event.EventType

    //Local view state
    @State private var showSaved: Bool = false
    @State private var showTypePopup: Bool = false
    @State private var openTypes: Set<Event.EventType> = []
    @State private var messageFieldFocused = true
    @State private var isDismissing = false


    var body: some View {
        VStack(alignment: .leading, spacing: 56) {
            messageTitle
            VStack(spacing: 20) {
                typeDropdown
                CustomTextField(
                    text: $message,
                    isFocused: $messageFieldFocused,
                    placeHolder: eventType.textPlaceholder
                )
                .sheetKeyboardOverlapTarget()
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, Spacing.margin)
        .frame(maxHeight: .infinity, alignment: .top)
        .sheetKeyboardOverlap(isFocused: $messageFieldFocused, isDismissing: $isDismissing) {
            doneButton
        }
        .savedFeedback(isPresented: $showSaved, tracking: message)
        .onAppear {
            messageFieldFocused = true
            isDismissing = false
        }
        .onDisappear {
            InstantKeyboard.dismiss(
                isFocused: $messageFieldFocused,
                isDismissing: $isDismissing
            )
        }
    }
}

extension AddMessageView {
    private var messageTitle: some View {
        Text("Add a Note")
            .font(.title(28))
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) { savedOverlayIcon }
    }
    
    private var typeDropdown: some View {
        TimeCustomMenu(placementOffsetY: -36, isOpen: $showTypePopup) {
            SelectTypeView(
                openTypes: $openTypes,
                selectedType: $eventType, 
                showMessageScreen: .constant(false), message: ""
            )
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(eventType.longTitle).font(.body(17, .medium))
                DropDownButton(isOpen: showTypePopup)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, Spacing.xxs) //Looks better sligtly inset
    }
    
    private var savedOverlayIcon: some View {
        SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: false)
            .opacityPop(visible: showSaved)
    }
    
    private var doneButton: some View {
        WideActionButton(text: "Done", isActive: true) {
            InstantKeyboard.dismiss(
                isFocused: $messageFieldFocused,
                isDismissing: $isDismissing
            )
            dismiss()
        }
        .padding(.bottom, Spacing.md)
        .padding(.horizontal, Spacing.margin)
    }
}
