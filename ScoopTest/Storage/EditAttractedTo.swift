////
////  EditAttractedTo.swift
////  ScoopTest
////
////  Created by Art Ostin on 12/07/2025.
////
//
//import SwiftUI
//
//struct EditAttractedTo: View {
//        
//    @Environment(\.appDependencies) private var dependencies: AppDependencies
//    
////    @Binding var vm: EditProfileViewModel
//    
//    
//    
//    @State var isSelected: String?
//    
//    @Binding var screenTracker: OnboardingViewModel
//    
//    let title: String?
//    
//    var isOnboarding: Bool
//    
//    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil /*vm: Binding<EditProfileViewModel>*/) {
//        self.isOnboarding = isOnboarding
//        self.title = title
//        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())
////        self._vm = vm
//    }
//
//    var body: some View {
//        
//        let manager = dependencies.profileManager
//
//        EditOptionLayout(title: title, isSelected: $isSelected) {
//            HStack {
//                OptionPill(title: "Men",counter: $screenTracker.screen, isSelected: $isSelected) { Task {try await manager.update(values: [.attractedTo : "Men"])}}
//                Spacer()
//                OptionPill(title: "Women", counter: $screenTracker.screen, isSelected: $isSelected) { Task{try await manager.update(values: [.attractedTo : "Women"])}}
//            }
//            HStack {
//                OptionPill(title: "Men & Women", counter: $screenTracker.screen,  isSelected: $isSelected) { Task{try await manager.update(values: [.attractedTo : "Men & Women"])}}
//                Spacer()
//                OptionPill(title: "All Genders", counter: $screenTracker.screen, isSelected: $isSelected) { Task{try await manager.update(values: [.attractedTo : "All Genders"])}}
//            }
//        }
//        .customNavigation(isOnboarding: isOnboarding)
//        .onAppear {isSelected = dependencies.userStore.user?.attractedTo }
//    }
//}
//
////#Preview {
////    EditAttractedTo()
////}
