//
//  MeetContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//



enum MeetSections {
    case intro
    case twoDailyProfiles
    case profile(UserProfile)
}


import SwiftUI

struct MeetContainer: View {
        
    @State var vm: MeetUpViewModel
    
    init(dep: AppDependencies) {
        self._vm = State(initialValue: MeetUpViewModel(userStore: dep.userStore, profileManager: dep.profileManager))
    }
    
    var body: some View {
        
        ZStack {
            switch vm.state {
            case .intro:
                IntroView(vm: $vm)
                
            case .twoDailyProfiles:
                DailyProfiles(vm: $vm)
                
            case .profile(let profile):
                ProfileView(profile: profile, vm2: $vm)
            default: EmptyView()
            }
        }.task {
            await vm.load()
        }
    }
}

#Preview {
    MeetContainer(dep: AppDependencies())
}
