//
//  RespondTimeView.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//

import SwiftUI

struct RespondTimeRow: View {
    //Using vm as multiple respond models
    @Bindable var vm: RespondViewModel
    @Binding var showTimePopup: Bool
    @Binding var showMessageScreen: Bool
    
    var showOriginal: Bool {
        vm.respondDraft.respondType == .original
    }
    
    var body: some View {
        DropDownView(verticalOffset: 48, showDropDownShadow: true, showOptions: $showTimePopup) {
            HStack(spacing: 24) {
                imageIcon
                if showOriginal {originalTimeRow} else {customTimeRow}
            }
        } dropDown: {
            RespondSelectTime(vm: vm, showTimePopup: $showTimePopup)
        }
    }
}

//Logic with the standardTimeRow
extension RespondTimeRow {
    
    private var imageIcon: some View {
        Image("MiniClockIcon")
            .scaleEffect(1.3)
            .opacity(showTimePopup ? 0.02 : 1)
    }
    
    @ViewBuilder
    private var originalTimeRow: some View {
        if let date = vm.respondDraft.selectedDate {
            let message = vm.respondDraft.event.message
            let hasMessage = !(message?.isEmpty ?? true)
            
            VStack(alignment: .leading, spacing: 4) {
                selectedTime(date: date)
                Text(hasMessage ? message! : hour)
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .opacity(hasMessage && showTimePopup ? 0.05 : 1)
                    .lineLimit(hasMessage ? 4 : nil)
            }
        }
    }
    
    private func selectedTime(date: Date) -> some View {
        HStack {
            Text(FormatEvent.dayAndTime(date))
                .font(.body(16, showTimePopup ? .bold : .medium))
            Spacer()
            DropDownButton(isExpanded: $showTimePopup, isAccept: true, showGlass: true)
        }
    }
}

//Logic with CustomTimeRow
extension RespondTimeRow {
    
    @ViewBuilder
    private var customTimeRow: some View {
        let dates = vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted()
        VStack(alignment: .leading, spacing: 6) {
    
            ProposedTimesRow(dates: dates, showTimePopup: $showTimePopup)
            if let message = vm.respondDraft.newTime.event.message {
                respondMessage(name: vm.respondDraft.newTime.event.otherUserName, message: message, isResponse: false)
                    .overlay(alignment: .bottomTrailing) {
                        if vm.respondDraft.newTime.message == nil {
                            addMessageButton(isEdit: false)
                        }
                    }
            }
            if let message = vm.respondDraft.newTime.message {
                messageResponse(message)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var hour: String {
        guard let date = vm.respondDraft.newTime.proposedTimes.dates.compactMap({ $0.date }).first else {return ""}
        return FormatEvent.hourTime(date)
    }
        
    private func respondMessage(name: String = "You", message: String, isResponse: Bool) -> some View {
        Group {
            Text(name)
                .foregroundStyle(isResponse ? .accent.opacity(0.4) : Color.gray)
            +
            
            Text(" - \(message)")
        }
        .font(.footnote)
        .foregroundStyle(.gray)
        .opacity(showTimePopup ? 0.1 : 1)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
        .italic()
        .multilineTextAlignment(isResponse ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: isResponse ? .leading : .trailing)
    }
    
    
    
    private func messageResponse(_ message: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            respondMessage(message: message, isResponse: true)
            addMessageButton(isEdit: true)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.top, 6) // Gives it 16 padding in total
    }
    
    private func addMessageButton(isEdit: Bool) -> some View {
        Button {
            showMessageScreen.toggle()
        } label: {
            Text(isEdit ? "Edit Message" : "Add Message")
            .foregroundStyle(Color.accent)
            .font(.custom("SFProRounded-Bold", size: 10))
            .kerning(0.5)
            .padding(12)
            .contentShape(.rect)
            .padding(-12)
            .offset(y: isEdit ? 0 : 16)
        }
    }
}

/*
 
 @ViewBuilder
 private var messageSection: some View {
     if let message = vm.respondDraft.event.message {
         Text(message)
             .font(.footnote)
             .foregroundStyle(.gray)
             .opacity(showTimePopup ? 0.1 : 1)
             .lineLimit(nil)
             .fixedSize(horizontal: false, vertical: true)
             .layoutPriority(1)
             .italic()
     }
 }

 */
