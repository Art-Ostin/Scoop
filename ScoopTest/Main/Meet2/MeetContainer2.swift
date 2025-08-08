//
//  MeetContainer2.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct MeetContainer2: View {
    
    var dep: AppDependencies
    @State private var vm: MeetUpViewModel2
    
    
    init(dep: AppDependencies) {
        self.dep = dep
        _vm = .init(initialValue: MeetUpViewModel2(dep: dep))
    }
    
    var body: some View {
        
        VStack(spacing: 32) {
            Text("Meet")
                .font(.body(32, .bold))
            ZStack {
                if (dep.defaultsManager.getDailyProfileTimerEnd() != nil) {
                    DailyProfiles2()
                } else {
                    IntroView2(vm: $vm)
                }
            }
        }
        .padding(.top, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
//    MeetContainer2()
}
