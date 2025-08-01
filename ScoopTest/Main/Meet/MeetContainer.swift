//
//  MeetContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//



enum MeetSections {
    case intro
    case twoDailyProfiles
    case profile
}


import SwiftUI

struct MeetContainer: View {
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @State var vm: DailyProfilesStore
    
    init(dep: AppDependencies) {
        self._vm = State(initialValue: DailyProfilesStore(userStore: dep.userStore, profileManager: dep.profileManager))
    }
    
    @State private var state: MeetSections? = MeetSections.intro
    
    var body: some View {
        
        ZStack {
            
            switch state {
                
            case .intro:
                IntroView(state: $state)
                
            case .twoDailyProfiles:
                if let profile1 = vm.profile1, let profile2 = vm.profile2 {
                    TwoDailyProfilesView(state: $state, profile1: profile1, profile2: profile2)
                }
            case .profile:
                if let profile = dependencies.userStore.user {
                    ProfileView(profile: profile, state: $state)
                }
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

