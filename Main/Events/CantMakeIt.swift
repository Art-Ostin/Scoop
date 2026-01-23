//
//  CantMakeIT.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct CantMakeIt: View {
    
    @Environment(\.dismiss) private var dismiss
    @State var showCancelAlert: Bool = false
    
    let vm: EventViewModel
    
    let event: UserEvent
    
    var fullTime: String {
        EventFormatting.fullDate(event.time)
    }
    
    var hour: String {
        return event.time.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
    
    var body: some View {

        VStack(alignment: .leading, spacing: 24){
            Text("Can’t Make It?")
                .font(.body(24, .bold))
            
            Text("We get it, shit happens. You can cancel up to 10 hours before (No rescheduling)")
                             
            Text("But to deter people bailing from nerves or effort ")
            + Text("your account is frozen for 14 days 🥶")
                .foregroundStyle(Color(red: 0, green: 0.65, blue: 0.73))
            
            
            Text("If you don’t show, ")
            + Text("your account is permanently blocked, ")
                .font(.body(16, .bold))
            
            + Text("so better to cancel if you must")
            
            Image("Monkey")
                .frame(width: 240, height: 240)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(spacing: 16) {
                Text("Meeting \(event.otherUserName)")
                
                Text("\(fullTime) · \(hour)")
            }
            .font(.body(18, .medium))
            .frame(maxWidth: .infinity)
            
            cancelButton
        }
        .font(.body(16, .medium))
        .lineSpacing(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 24)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body(17, .bold))
                        .foregroundStyle(Color.primary)
                        .padding(14)
                        .glassIfAvailable(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
        .background(Color.background)
        .customAlert(isPresented: $showCancelAlert, title: "Cancel Date",cancelTitle: "Back", okTitle: "Confirm", emoji: "🚨", message: "Are you sure? Scoop will be frozen for two weeks & all pending invites removed", showTwoButtons: true) {
            
            //Implement code to actually freeze profile here (need a timer)
        }
        .interactiveDismissDisabled(showCancelAlert)
    }
}

extension CantMakeIt {
    
    private var cancelButton: some View {
        Button {
            showCancelAlert.toggle()
        } label: {
            Text("Cancel Date")
                .frame(width: 120, height: 35)
                .stroke(10, lineWidth: 2, color: Color.dangerRed)
                .foregroundStyle(Color.dangerRed)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        }
    }
    
    private var frozenUntilDate: String {
        let frozenUntil = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let full = EventFormatting.fullDate(frozenUntil)
        let monthText = frozenUntil.formatted(.dateTime.month(.wide))
        let secondWord = full.split(whereSeparator: \.isWhitespace).dropFirst().first.map(String.init) ?? ""
        
        return "the \(secondWord) of \(monthText)"
    }
    
}
