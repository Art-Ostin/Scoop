//
//  EditSex.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct EditSex: View {
    
    var isOnboarding: Bool
        
    @State private var isSelected: String?
    
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    private var vm: EditProfileViewModel { dependencies.editProfileViewModel}
    
    let title: String?
    
    @Binding var screenTracker: OnboardingViewModel
        
    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil) {
        self.isOnboarding = isOnboarding
        self.title = title
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())
    }
    
    var body: some View {
        let user = dependencies.userStore.user
        
        EditOptionLayout(title: title, isSelected: $isSelected) {
            HStack {
                OptionPill(title: "Man", counter: $screenTracker.screen, isSelected: $isSelected) {
                    try dependencies.profileManager.updateSex(userId: vm.user.userId, sex: "Man")
                }
                
                
                
                Spacer()
                OptionPill(title: "Women", counter: $screenTracker.screen, isSelected: $isSelected) {
                    try dependencies.profileManager.updateSex(userId: vm.user.userId, sex: "Women")
                }
            HStack {
                Spacer()
                OptionPill(title: "Beyond Binary", counter: $screenTracker.screen, isSelected: $isSelected) {
                    try dependencies.profileManager.updateSex(userId: vm.user.userId, sex: "BeyondBinary")
                }
                Spacer()
            }
        }
        .customNavigation(isOnboarding: isOnboarding)
    }
}

#Preview {
    EditSex()
}
