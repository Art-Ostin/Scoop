//
//  RespondTimeContainer.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

struct RespondTimeContainer: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    @State var ui = TimeAndPlaceUIState ()
    @Binding var selectedDay: Date?
    @Binding var showTime: Bool
    let dates: [Date]

    @State var showCustomTime: Bool = false
    
    var body: some View {
        if showCustomTime {
            SelectTimeView(vm: vm, showTimePopup: $showTime, isRespondMode: true, showInvitedTimes: $showCustomTime)
        } else {
            SelectRespondTime(selectedDay: $selectedDay, showTime: $showTime, dates: dates, showCustomTime: $showCustomTime)
        }
    }
}
