//
//  InviteAddMessageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI
import UIKit


struct AddMessageView: View {
    
    //1. Dismiss Logic
    @Environment(\.dismiss) private var dismiss
    
    //2.Message which bound to 
    @Binding var message: String?
    
    //3. UI Display Logic
    @State var showSaved: Bool = false
    @State var hasEditedThisSession: Bool = false
    @State private var keyPressToken = 0

    private let messageLimit = 130
    private let warningThreshold = 25

    //4. Key parameters to update
    let isRespondMessage: Bool
    var name: String? = nil

    //5. Logic for choosing type here
    @State var showTypePopup: Bool = false
    @State private var openTypes: Set<Event.EventType> = []
    @Binding var eventType: Event.EventType
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 36) {
            VStack(spacing: 16) {
                dropdownTitle
                    .frame(maxWidth: .infinity, alignment: .trailing)
                textFieldSection
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 36)
            
            doneButton
        }
        .navigationTitle("Add Message")
        .navSubTitle("Improve your invite with a message")
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .top)
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
        TimeCustomMenu {
            selectTypeView
        } label: {
            selectTypeTitle
        }
    }
    
    private var textFieldSection: some View {
        
        let textFont = UIFont.body(18)

        return FocusedTextView(
            text: $message,
            font: textFont,
            lineSpacing: 5,
            placeholderLineSpacing: 6,
            placeholderFont: .body(textFont.pointSize, .regular),
            maxLength: messageLimit,
            placeholder: eventType.textPlaceholder
        )
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .stroke(12, lineWidth: 1, color: Color.grayPlaceholder)
            .overlay(alignment: .bottomTrailing) {
                let remaining = max(0, messageLimit - (message ?? "").count)
                if remaining <= warningThreshold {
                    Text("\(remaining)")
                        .font(.body(14))
                        .foregroundStyle(Color.warningYellow)
                        .padding(.trailing, 12)
                        .padding(.bottom, 10)
                }
            }
        }
    
    @ViewBuilder private var savedOverlayIcon: some View {
        if showSaved {
            SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: false)
                .offset(y: -36)
                .padding(.horizontal, 24)
        }
    }
    
    private var doneButton: some View {
        ScoopButton(style: .tinted(.accent, shadow: .low), shape: .rect(cornerRadius: 24), action: {dismiss()}) {
            Text("Done")
                .font(.body(18, .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .geometryGroup()

        }
        .padding(.top, 24)
    }
    
    
    private var selectTypeTitle: some View {
        HStack(spacing: 12) {
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
            showTypePopup: $showTypePopup,
            message: "",
            cardCorners: RectangleCornerRadii(uniform: 20)
        )
        // Opaque backing so the menu's translucent glass platter can't lens the
        // red (accent) Done button sitting behind this popup's floating window.
        // Same appCanvas fill used by inviteCardBackground / RespondTimeBackground.
        .background(Color.appCanvas, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .compositingGroup()
    }
}

extension AddMessageView {
    
    private func showSakedButton() async {
        guard hasEditedThisSession else { return }
        if keyPressToken != 0 {
            withAnimation(.smooth()) { showSaved = true }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.snappy()) { showSaved = false}
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
