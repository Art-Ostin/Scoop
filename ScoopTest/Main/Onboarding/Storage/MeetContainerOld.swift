////
////  MeetContainerView.swift
////  ScoopTest
////
////  Created by Art Ostin on 11/06/2025.
////
//
//
//
//enum MeetSections {
//    case intro
//    case twoDailyProfiles
//    case profile(UserProfile)
//}
//
//
//import SwiftUI
//
//struct MeetContainer: View {
//        
//    @State var vm: MeetUpViewModel
//    
//    init(dep: AppDependencies) {
//        self._vm = State(initialValue: MeetUpViewModel(dep: dep))
//    }
//    
//    
//    var body: some View {
//        
//        ZStack {
//            switch vm.state {
//            case .intro:
//                IntroView(vm: $vm)
//                
//            case .twoDailyProfiles:
//                DailyProfiles(vm: $vm)
//                
//            case .profile(let profile):
//                ProfileView(profile: profile, vm2: $vm, dep: vm.dep)
//            default: EmptyView()
//            }
//        }
//    }
//}
//
//#Preview {
//    MeetContainer(dep: AppDependencies())
//}
