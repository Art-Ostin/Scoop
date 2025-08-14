//
//  MeetContainer2.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

/*
 
 import SwiftUI

 struct MeetContainer: View {
     
     var dep: AppDependencies
     
     @State private var vm: MeetViewModel
     
     @State var showProfiles: Bool
     @State private var selectedProfile: UserProfile?
     @State private var selectedInvite: EventInvite?
     
     init(dep: AppDependencies) {
         self.dep = dep
         _vm = .init(initialValue: MeetViewModel(dep: dep))
         self.showProfiles = dep.defaultsManager.getDailyProfileTimerEnd() != nil
     }
     
     var body: some View {
         ZStack {
             VStack(spacing: 32) {
                 Text("Meet")
                     .font(.body(32, .bold))
                 ZStack {
                     if showProfiles {
                         DailyProfiles(vm: $vm, showProfile: $showProfiles, selectedProfile: $selectedProfile, selectedInvite: $selectedInvite)
                     } else {
                         IntroView(vm: $vm, showProfiles: $showProfiles)
                     }
                 }
             }
             .task {
                 if vm.profileRecs.isEmpty { await vm.loadProfileRecs() }
                 if vm.profileInvites.isEmpty { await vm.loadEventInvites() }
             }
             
             
             .padding(.top, 36)
             .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
             
             
             
             
             
             if let profile = selectedProfile {
                 ZStack {
                     Color.clear
                         .contentShape(Rectangle())
                         .ignoresSafeArea()
                         .onTapGesture { }
                     ProfileView(profile: profile, dep: dep) {
                         withAnimation(.easeInOut(duration: 0.2)) { selectedProfile = nil }
                     }
                 }
                 .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom)))
                 .zIndex(1)
             }
             
             if let invite = selectedInvite {
                 ZStack {
                     Color.clear
                         .contentShape(Rectangle())
                         .ignoresSafeArea()
                         .onTapGesture { }
                     ProfileView(profile: invite.profile, dep: dep, event: invite.event) {
                         withAnimation(.easeInOut(duration: 0.2)) { selectedInvite = nil }
                     }
                 }
             }
         }

     }
 }
 
 */

