//
//  InviteSelectTimeView.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//
 
 import SwiftUI

 struct InviteSelectTimeView: View {
          
     @Binding var showTimePopup: Bool
     @Bindable var vm: RespondViewModel
     
     @State var isFlipped  = false
     

         
     var body: some View {
         ZStack {
             SelectAvailableDay(event: vm.respondDraft.event, selectedDay: $vm.respondDraft.selectedDate ,showTimePopup: $showTimePopup)
             .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
             .opacity(isFlipped ? 0 : 1)
             
             SelectTimeView(proposedTimes: $vm.respondDraft.newTime.proposedTimes, showTimePopup: $showTimePopup)
             .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
             .opacity(isFlipped ? 1 : 0)
         }
         .animation(.easeInOut(duration: 0.2), value: isFlipped)
         .onTapGesture {
             isFlipped.toggle()
         }
     }
 }


