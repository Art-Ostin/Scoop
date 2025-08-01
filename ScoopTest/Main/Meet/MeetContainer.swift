//
//  MeetContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//



enum MeetSections {
    case intro
    case twoDailyProfiles
    case profile1
    case profile2
}


import SwiftUI

struct MeetContainer: View {
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @State var vm: MeetUpViewModel?
    
    init(dep: AppDependencies) {
        self._vm = State(initialValue: MeetUpViewModel(userStore: dep.userStore, profileManager: dep.profileManager))
    }
    
    var body: some View {
        
        ZStack {
            
            switch vm?.state {
                
            case .intro:
                IntroView(vm: $vm)
                
            case .twoDailyProfiles:
                TwoDailyProfilesView(vm: $vm)
                
            case .profile1:
                if let profile1 = vm?.profile1 {
                    ProfileView(profile: profile1, vm2: $vm)
                }
            case .profile2:
                if let profile2 = vm?.profile2 {
                    ProfileView(profile: profile2, vm2: $vm)
                }
            default: EmptyView()
            }
        }.task {
            await vm?.load()
        }
    }
}

#Preview {
    MeetContainer(dep: AppDependencies())
}



//
//@Observable class MeetContainerViewModel {
//
//
//    var meetSection: MeetSections = .intro
//
//    let dailyProfiles: DailyProfilesStore
//    let userStore: CurrentUserStore
//
//
//    var profiles: [ProfileViewModel] = []
//
//    var profile1: UserProfile?
//    var profile2: UserProfile?
//
//
//    init(profileManager: ProfileManaging, userStore: CurrentUserStore) {
//        self.dailyProfiles = profileManager
//        self.userStore = userStore
//    }
//
//    func loadProfiles() async {
//        profiles = dailyProfiles.load
//
//
//    }
//
//
//
//
//}

