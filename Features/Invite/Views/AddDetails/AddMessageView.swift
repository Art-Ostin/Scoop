//
//  InviteAddMessageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

 
import SwiftUI
import UIKit

struct AddMessageView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var eventType: Event.EventType
    @Binding var showMessageScreen: Bool
    @Binding var message: String?
    let isRespondMessage: Bool
    var name: String? = nil

    @State var showTypePopup: Bool = false
    @State var showSaved: Bool = false
    @State var hasEditedThisSession: Bool = false
    @State private var keyPressToken = 0
    @State private var openTypes: Set<Event.EventType> = []
        
    private let messageLimit = 130
    private let warningThreshold = 25
    

    var body: some View {
        
        VStack(alignment: .leading, spacing: 36) {
            headerSection
            
            textFieldSection
                .padding(.top, 24)
            
            ActionButton(text: "Done") { dismiss() }
                .padding(.top, isRespondMessage ? 24 : 36)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .overlay(alignment: .topTrailing) {
            if showSaved {
                SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: false)
                    .offset(y: -36)
            }
        }
        .overlay(alignment: .top) {addMessageNote}
        
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
            let emoji = eventType.emoji
            let type = eventType.title
            Text("\(emoji) \(type)")
                .foregroundStyle(.black)
                .font(.body(17))
                .contentShape(.rect)
                .onTapGesture { showTypePopup.toggle()}
            
            DropDownButton(isExpanded: $showTypePopup)
        }
    }
    
    private var textFieldSection: some View {
        FocusedTextView(text: $message, font: .body(18), lineSpacing: 5, placeholderLineSpacing: 6, maxLength: messageLimit, placeholder: eventType.textPlaceholder)
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
    
    
    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Add Message")
                .kerning(0.5)
                .font(.title(24))
            
            Spacer()
            
            if !isRespondMessage {
                DropDownView(shiftLeft: true, showOptions: $showTypePopup) {
                    dropdownTitle
                } dropDown: {
                    SelectTypeView(openTypes: $openTypes, selectedType: $eventType, showMessageScreen: $showMessageScreen, showTypePopup: $showTypePopup, message: message ?? "")
                }
            } else {
                let emoji = eventType.emoji
                let type = eventType.title
                Text("\(emoji) \(type)")
                    .font(.body(17, .bold))
                    .offset(y: -2)
            }
        }
        .frame(maxWidth: .infinity)
        .zIndex(1)
    }
    
    
    private var addMessageNote: some View {
        
        let text: String = isRespondMessage ?  "Accept \(name ?? "")'s invite with a message" :  "Add a note to your invite for \(name ?? "them")"
        
        return Text(text)
            .font(.body(14, .medium))
            .foregroundStyle(Color.grayText).opacity(0.8)
            .frame(maxWidth: .infinity, alignment: .center)
            .offset(y: -60)
    }
}

