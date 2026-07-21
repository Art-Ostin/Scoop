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
    @State private var savedIconTask: Task<Void, Never>?
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
        .sheetKeyboardOverlap(
            isFocused: $messageFieldFocused,
            isDismissing: $isDismissing
        ) {
            doneButton
        }
        .onAppear {
            savedIconTask?.cancel()
            showSaved = false
            messageFieldFocused = true
            isDismissing = false
        }
        .onChange(of: message) {
            flashSavedIcon()
        }
        .onDisappear {
            savedIconTask?.cancel()
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
    
    private func flashSavedIcon() {
        savedIconTask?.cancel()
        savedIconTask = Task { @MainActor in
            withAnimation(.toggle) { showSaved = true }
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
            withAnimation(.toggle) { showSaved = false }
        }
    }
}




/*
 
 
 
 
 private var textFieldSection: some View {
     InstantKeyboardField(
         text: $message,
         textLimit: messageLimit,
         placeholder: eventType.textPlaceholder,
         font: .body(18)
     )
         .padding(.horizontal)
         .frame(maxWidth: .infinity)
         .frame(height: 145)
         .customScrollFade(height: Spacing.lg, color: .white, edge: .top)
         .customScrollFade(height: Spacing.lg, color: .white, edge: .bottom)
         .clipShape(.rect(cornerRadius: CornerRadius.xl))
         .stroke(CornerRadius.xl, color: Color.border)
         .overlay(alignment: .bottomTrailing) {countRemainingText}
 }

 
 @ViewBuilder
 private var countRemainingText: some View {
     let remaining = max(0, messageLimit - (message ?? "").count)
     if remaining <= warningThreshold {
         Text("\(remaining)")
             .font(.body(14))
             .foregroundStyle(Color.warningYellow)
             .padding(.trailing, Spacing.sm)
             .padding(.bottom, Spacing.sm)
     }
 }

 
 
 
 .padding(.horizontal, Spacing.margin)
 .frame(maxHeight: .infinity, alignment: .top)
 .ignoresSafeArea(.keyboard, edges: .bottom)

 */
