//
//  EditAttractedTo.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct EditAttractedTo: View {
        
    @State var isSelected: String? = CurrentUserStore.shared.user?.attractedTo
    
    @Binding var screenTracker: OnboardingViewModel
    
    let title: String?
    
    var isOnboarding: Bool
    
    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil) {
        self.isOnboarding = isOnboarding
        self.title = title
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())}
    

    var body: some View {
        
        EditOptionLayout(title: title, isSelected: $isSelected) {
            HStack {
                OptionPill(title: "Men",counter: $screenTracker.screen, isSelected: $isSelected) { EditProfileViewModel.instance.updateAttractedTo(attractedTo: "Men")}
                Spacer()
                OptionPill(title: "Women", counter: $screenTracker.screen, isSelected: $isSelected) {EditProfileViewModel.instance.updateAttractedTo(attractedTo: "Women")}
            }
            
            HStack {
                OptionPill(title: "Men & Women", counter: $screenTracker.screen,  isSelected: $isSelected) {EditProfileViewModel.instance.updateAttractedTo(attractedTo: "Men & Women")}
                Spacer()
                OptionPill(title: "All Genders", counter: $screenTracker.screen, isSelected: $isSelected) {EditProfileViewModel.instance.updateAttractedTo(attractedTo: "All Genders")}
            }
        }
        .customNavigation(isOnboarding: isOnboarding)
    }
}

#Preview {
    EditAttractedTo()
}
