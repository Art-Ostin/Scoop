//
//  TimePopupContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct TimePopupContainer: View {
    
    //Injected -- three values can change (1) The response Type (2) The selected Day (3) Modified Invite proposed Times
    @Binding var respondType: ResponseType
    @Binding var selectedDay: Date?
    @Binding var newProposedTimes: ProposedTimes
    
    //ProposedTimes open here.
    let times: ProposedTimes
    
    
    @State var showNewTimeMenu = false
    
    var body: some View {
        VStack {
            Text("")
            
            
            
            Text("Hello World")
            
        }
        .frame(width: 100, height: 150)
        .background(Color.appCanvas, in: .rect(cornerRadius: 36))
    }
}


extension TimePopupContainer {
    
    private var popupTitle: some View {
        VStack(spacing: 24) {
            Text(showNewTimeMenu ? "Invited Times" : "Choose New Time")
                .font(.body(17, .medium))
                .foregroundStyle(Color.textPrimary)

            
            Text("Propose 1-3 days to meet")
                .font(.body(11, .regular))
                .foregroundStyle(Color.textTertiary)
        }
    }
    
    
    
}

/*
 private var titleSection: some View {
     HStack(alignment: .top) {
         VStack(alignment: .leading, spacing: 4) {
             Text("Choose Time") //"Propose up to 3 days"
                 .font(.body(17, .medium))
                 .foregroundStyle(Color.textPrimary)
             Text("Propose 1-3 days to meet")
                 .font(.body(11, .regular))
                 .foregroundStyle(Color.textTertiary)
         }
         Spacer()
     }
     .overlay(alignment: .topTrailing) { timeAndWarningSign }
 }

 */
