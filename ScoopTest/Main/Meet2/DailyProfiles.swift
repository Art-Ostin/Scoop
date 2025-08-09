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
    
    var body: some View {
        
        let time = vm.dep.defaultsManager.getDailyProfileTimerEnd()
        
        VStack(spacing: 36) {
            
            ForEach(vm.shownDailyProfiles) {profile in
                Text(profile.name ?? "")
            }

            if let time {
                SimpleClockView(targetTime: time, showProfile: $showProfile)
            }
        }
    }
}
//
//#Preview {
//    DailyProfiles2()
//}
