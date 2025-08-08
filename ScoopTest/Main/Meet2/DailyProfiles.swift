//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct DailyProfiles2: View {
    
    @Binding var vm: MeetUpViewModel2
    
    
    var body: some View {
        
        let time = vm.dep.defaultsManager.getDailyProfileTimerEnd()
        
        VStack(spacing: 36) {
            Text("Hello World")
            
            if let time {
                SimpleClockView(targetTime: time)
            }
        }
    }
}
//
//#Preview {
//    DailyProfiles2()
//}
