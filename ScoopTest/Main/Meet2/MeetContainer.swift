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
    
    @State var showProfiles: Bool
    
    init(dep: AppDependencies) {
        self.dep = dep
        _vm = .init(initialValue: MeetUpViewModel2(dep: dep))
        self.showProfiles = dep.defaultsManager.getDailyProfileTimerEnd() != nil
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Meet")
                .font(.body(32, .bold))
            ZStack {
                if showProfiles {
                    DailyProfiles2(vm: $vm, showProfile: $showProfiles)
                } else {
                    IntroView2(vm: $vm, showProfiles: $showProfiles)
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
