//
//  RespondTimeContainer.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

/*
 import SwiftUI

 struct RespondTimeContainer: View {
     
     @Bindable var vm: TimeAndPlaceViewModel
     @Binding var selectedDay: Date?
     @Binding var showTime: Bool
     let times: [ProposedTime]
     @State var showCustomTime: Bool = false
     @Namespace private var ns
     
     var body: some View {
         
         
         
         ZStack(alignment: .topLeading) {
             if showCustomTime {
                 SelectTimeView(vm: vm, showTimePopup: $showTime, isRespondMode: true, showInvitedTimes: $showCustomTime)
                     .matchedGeometryEffect(id: "respondTimeContent", in: ns, properties: .frame, anchor: .topLeading)
             } else {
                 SelectRespondTime(selectedDay: $selectedDay, showTime: $showTime, times: times, showCustomTime: $showCustomTime)
                     .matchedGeometryEffect(id: "respondTimeContent", in: ns, properties: .frame, anchor: .topLeading)
             }
         }
         .animation(.easeInOut(duration: 0.2), value: showCustomTime)
     }
 }
 */
