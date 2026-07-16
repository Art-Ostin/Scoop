//
//  InviteAddMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI
import UIKit


struct AddMessageView: View {
    
    //Injected
    @Environment(\.dismiss) private var dismiss
    @Binding var message: String?
    let isRespondMessage: Bool
    var name: String? = nil
    @Binding var eventType: Event.EventType

    //Local view state
    @State private var showSaved: Bool = false
    @State private var hasEditedThisSession: Bool = false
    @State private var keyPressToken = 0
    @State private var showTypePopup: Bool = false
    @State private var openTypes: Set<Event.EventType> = []

    private let messageLimit = 130
    private let warningThreshold = 25


    var body: some View {
        
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                dropdownTitle
                    .frame(maxWidth: .infinity, alignment: .trailing)
                textFieldSection
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, Spacing.lg)
            
            doneButton
        }
        .navigationTitle("Add Message")
        .navSubTitle("Improve your invite with a message")
        .padding(.horizontal, Spacing.margin)
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard, edges: .bottom) 
        .overlay(alignment: .topTrailing) {savedOverlayIcon}
        
        //All Logic dealing with SavedIcon
        .task(id: message) { await showSakedButton() }
        .onAppear {
            hasEditedThisSession = false
            showSaved = false
        }
        .onChange(of: message) {
            hasEditedThisSession = true
            keyPressToken &+= 1
        }
    }
}

extension AddMessageView {
    @ViewBuilder
    private var dropdownTitle: some View {
        TimeCustomMenu(
            placementOffsetY: TimeCustomMenuSpec.placementOffsetY + Spacing.xl,
            onOpen: { showTypePopup = true },
            onClose: { showTypePopup = false }
        ) {
            selectTypeView
        } label: {
            selectTypeTitle
        }
    }
    
    private var textFieldSection: some View {
        
        let textFont = UIFont.body(18)
        let textViewBackground = Color.appCanvas

        return FocusedTextView(
            text: $message,
            font: textFont,
            lineSpacing: 5,
            placeholderLineSpacing: 6,
            placeholderFont: .body(textFont.pointSize, .regular),
            maxLength: messageLimit,
            placeholder: eventType.textPlaceholder,
            backgroundColor: textViewBackground
        )
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(textViewBackground)
            .customScrollFade(height: Spacing.lg, color: textViewBackground, edge: .top)
            .customScrollFade(height: Spacing.lg, color: textViewBackground, edge: .bottom)
            .clipShape(.rect(cornerRadius: CornerRadius.sm))
            .stroke(CornerRadius.sm)
            .overlay(alignment: .bottomTrailing) {
                let remaining = max(0, messageLimit - (message ?? "").count)
                if remaining <= warningThreshold {
                    Text("\(remaining)")
                        .font(.body(14))
                        .foregroundStyle(Color.warningYellow)
                        .padding(.trailing, Spacing.sm)
                        .padding(.bottom, Spacing.sm)
                }
            }
        }
    
    @ViewBuilder private var savedOverlayIcon: some View {
        if showSaved {
            SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: false)
                .offset(y: -36)
                .padding(.horizontal, Spacing.margin)
        }
    }
    
    private var doneButton: some View {
        ScoopButton(style: .tinted(.textAccent), shape: .rect(cornerRadius: CornerRadius.xl), action: {dismiss()}) {
            Text("Done")
                .font(.body(18, .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .geometryGroup()

        }
        .padding(.top, Spacing.xl)
    }
    
    
    private var selectTypeTitle: some View {
        HStack(spacing: Spacing.sm) {
            Text(eventType.longTitle)
                .font(.body(17, .medium))
            DropDownButton(isOpen: showTypePopup)

        }
    }
    
    
    private var selectTypeView: some View {
        SelectTypeView(
            openTypes: $openTypes,
            selectedType: $eventType,
            showMessageScreen: .constant(false),
            message: ""
        )
        .background(Color.appCanvas, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .compositingGroup()
    }
}

extension AddMessageView {
    
    private func showSakedButton() async {
        guard hasEditedThisSession else { return }
        if keyPressToken != 0 {
            withAnimation(.toggle) { showSaved = true }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.toggle) { showSaved = false}
        }
    }
}


extension View {
    
    func navSubTitle(_ text: String) -> some View {
        if #available(iOS 26.0, *) {
            return self
                .navigationSubtitle(text)
        } else {
            return self
        }
    }
}
