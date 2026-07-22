//
//  RespondNewTime.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct RespondNewTime: View {
    
    @Binding var proposedTimes: ProposedTimes
    
    @State var dayWarning: DayWarning? = nil
    
    var body: some View {
        VStack {
            
            DayPicker(proposedTimes: $proposedTimes, dayWarning: $dayWarning, selectedHour: 4, selectedMinute: 30)
            
            
        }
        .foregroundStyle(Color.black)
    }
}
