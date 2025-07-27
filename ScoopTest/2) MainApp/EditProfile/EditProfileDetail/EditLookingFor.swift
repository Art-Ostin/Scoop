//
//  EditLookingFor.swift
//  ScoopTest
//
//  Created by Art Ostin on 13/07/2025.
//

import SwiftUI

struct EditLookingFor: View {
        
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    var vm: EditProfileViewModel { dependencies.editProfileViewModel }
    @State var isSelected: String?
    
    
    var isOnboarding: Bool
    let title: String?
    
    @Binding var screenTracker: OnboardingViewModel
        
    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil) {
        self.isOnboarding = isOnboarding
        self.title = title
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())
    }
    
    var body: some View {
        EditOptionLayout(title: title, isSelected: $isSelected) {
            HStack {
                OptionPill(title: "Short-term", counter: $screenTracker.screen, isSelected: $isSelected) { vm.updateLookingFor(lookingFor: "Short-term")}
                Spacer()
                OptionPill(title: "Long-term", counter: $screenTracker.screen, isSelected: $isSelected) {vm.updateLookingFor(lookingFor: "Long-term") }
            }
            HStack {
                Spacer()
                OptionPill(title: "Undecided", counter: $screenTracker.screen, isSelected: $isSelected) {vm.updateLookingFor(lookingFor: "Undedcided")}
                Spacer()
            }
        }
        .customNavigation(isOnboarding: isOnboarding)
        .onAppear {isSelected = dependencies.userStore.user?.lookingFor }
    }
}

#Preview {
    EditLookingFor(title: "Looking For")
}




