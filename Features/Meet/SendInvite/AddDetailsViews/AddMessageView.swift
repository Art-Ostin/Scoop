//
//  InviteAddMessageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

 
import SwiftUI
import UIKit

struct AddMessageView: View {
    
    @Binding var eventType: Event.EventType?
    @Binding var showMessageScreen: Bool
    @Binding var message: String?
    let isRespondMessage: Bool
    var name: String? = nil

    @State var showTypePopup: Bool = false
    @State var showSaved: Bool = false
    @State var hasEditedThisSession: Bool = false
    @State private var keyPressToken = 0
        
    private let messageLimit = 130
    private let warningThreshold = 25
    

    var body: some View {
        
        VStack(alignment: .leading, spacing: 36) {
            headerSection
            
            textFieldSection
                .padding(.top, 24)
            
            OkDismissButton()
                .padding(.top, isRespondMessage ? 24 : 36)
        }
        .overlay(alignment: .topTrailing) {
            if showSaved {
                SavedIcon(topPadding: 0, horizontalPadding: 0)
                    .offset(y: -36)
            }
        }
        .overlay(alignment: .top) {
            if isRespondMessage {
                Text("Accept \(name ?? "")'s invite with a message")
                    .font(.body(14, .medium))
                    .foregroundStyle(Color.grayText).opacity(0.8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: -60)
            }
        }
        .padding(.top, isRespondMessage ? 108 : 96)
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.2), value: showTypePopup)
        
        //All Logic dealing with SavedIcon
        .task(id: message) {
            guard hasEditedThisSession else { return }
            if keyPressToken != 0 {
                withAnimation(.smooth()) { showSaved = true }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation(.smooth()) { showSaved = false}
            }
        }
        .onAppear {
            hasEditedThisSession = false
            showSaved = false
        }
        .onChange(of: message) {
            hasEditedThisSession = true
            keyPressToken &+= 1
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
        
        HStack(spacing: 10) {
            if let eventType {
                let emoji = eventType.description.emoji
                let type = eventType.description.label
                Text("\(emoji) \(type)")
                    .foregroundStyle(.black)
                    .font(.body(17))
                    .contentShape(.rect)
                    .onTapGesture { showTypePopup.toggle()}
            } else {
                Text("Choose a type")
                    .font(.body(15, .italic))
            }
            
            DropDownButton(isExpanded: $showTypePopup)
        }
    }
    
    private var textFieldSection: some View {
        FocusedTextView(text: $message, font: .body(18), lineSpacing: 5, placeholderLineSpacing: 6, maxLength: messageLimit, placeholder: eventType?.textPlaceholder)
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .stroke(12, lineWidth: 1, color: .grayPlaceholder)
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
    
    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Add Message")
                .font(.custom("SFProRounded-Bold", size: 24))
            
            Spacer()
            
            if !isRespondMessage {
                DropDownView(shiftLeft: true, showOptions: $showTypePopup) {
                    dropdownTitle
                } dropDown: {
                    SelectTypeView(type: $eventType, showMessageScreen: $showMessageScreen, showTypePopup: $showTypePopup, message: message ?? "")
                }
            } else {
                if let eventType {
                    let emoji = eventType.description.emoji
                    let type = eventType.description.label
                    Text("\(emoji) \(type)")
                        .font(.body(17, .bold))
                        .offset(y: -2)
                } else {
                    Text("Choose type")
                        .font(.body(15, .italic))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .zIndex(1)
    }
}

/*
 
 private var messageBinding: Binding<String> {
     Binding(
         get: { vm.event.message ?? "" },
         set: { vm.event.message = $0 }
     )
 }

 @Bindable var vm: TimeAndPlaceViewModel
 @Bindable var ui: TimeAndPlaceUIState

 */
