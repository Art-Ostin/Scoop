//
//  EditLookingFor.swift
//  ScoopTest
//
//  Created by Art Ostin on 13/07/2025.
//

import SwiftUI

struct EditLookingFor: View {
        
    let vm = EditProfileViewModel.instance
    
    var isOnboarding: Bool
    
    @State private var isSelected: String? = EditProfileViewModel.instance.user?.lookingFor
    
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
    }
}

#Preview {
    EditLookingFor(title: "Looking For")
}




