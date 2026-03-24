//
//  InviteSelectTimeView.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//
 
 import SwiftUI

 struct InviteSelectTimeView: View {
     
     let event: UserEvent
     
     @State var isFlipped  = false
     
     @Binding var showTimePopup: Bool
     @Binding var selectedDay: Date?
     
     @Bindable var vm: RespondViewModel

     @State var ui =  TimeAndPlaceUIState()
         
     var body: some View {
         ZStack {
             SelectAvailableDay(event: event, selectedDay: $selectedDay,showTimePopup: $showTimePopup)
             .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
             .opacity(isFlipped ? 0 : 1)

             SelectTimeView(proposedTimes: $vm.respondDraft.event.proposedTimes, showTimePopup: $showTimePopup, isRespondMode: true)
             .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
             .opacity(isFlipped ? 1 : 0)
         }
         .animation(.easeInOut(duration: 0.2), value: isFlipped)
         .onTapGesture {
             isFlipped.toggle()
         }
     }
 }


