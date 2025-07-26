//
//  EditSex.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct EditSex: View {
    
    var isOnboarding: Bool
    
    @State private var isSelected: String? = CurrentUserStore.shared.user?.sex
    
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
                OptionPill(title: "Man", counter: $screenTracker.screen, isSelected: $isSelected) {
                    EditProfileViewModel.instance.updateSex(sex: "Man")
                }
                Spacer()
                OptionPill(title: "Women", counter: $screenTracker.screen, isSelected: $isSelected) {
                    EditProfileViewModel.instance.updateSex(sex: "Women")}
            }
            HStack {
                Spacer()
                OptionPill(title: "Beyond Binary", counter: $screenTracker.screen, isSelected: $isSelected) {
                    EditProfileViewModel.instance.updateSex(sex: "Beyond Binary")
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
