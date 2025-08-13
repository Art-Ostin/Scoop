//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct DailyProfiles: View {
    
    @Binding var vm: MeetViewModel
    @Binding var showProfile: Bool
    @Binding var selectedProfile: UserProfile?
    
    
    var body: some View {
        
        let time = vm.dep.defaultsManager.getDailyProfileTimerEnd()

        VStack(spacing: 36) {

            TabView {
                
                ForEach(vm.profileInvites, id: \.self) { profile, event in
                    ProfileCard(userEvent: event, profile: profile, dep: vm.dep, selectedProfile: $selectedProfile)                    
                }
                
                
                ForEach(vm.profileRecs) {profile in
                    ProfileCard(profile: profile, dep: vm.dep,  selectedProfile: $selectedProfile)
                }
            }
            .task {
                await vm.loadProfileRecs()
                await vm.loadEventInvites()
                
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            if let time {
                SimpleClockView(targetTime: time, showProfile: $showProfile) {
                    vm.dep.defaultsManager.deleteTwoDailyProfiles()
                    showProfile = false
                    print("deleted old profiles")
                }
            }
        }
    }
}
