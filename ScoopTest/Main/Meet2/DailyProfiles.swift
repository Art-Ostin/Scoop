//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct DailyProfiles2: View {
    
    @Binding var vm: MeetUpViewModel2
    @Binding var showProfile: Bool
    @Binding var selectedProfile: UserProfile?
    
    
    var body: some View {
        
        let time = vm.dep.defaultsManager.getDailyProfileTimerEnd()
        
        VStack(spacing: 36) {
            
            TabView {
                ForEach(vm.shownDailyProfiles) {profile in
                    ProfileCard(profile: profile, dep: vm.dep,  selectedProfile: $selectedProfile)
                }
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
