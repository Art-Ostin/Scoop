//
//  EditLookingFor.swift
//  ScoopTest
//
//  Created by Art Ostin on 13/07/2025.
//

import SwiftUI

struct EditLookingFor: View {
    
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    @Binding var vm: EditProfileViewModel
    
    
    @State var isSelected: String?
    
    
    var isOnboarding: Bool
    let title: String?
    
    @Binding var screenTracker: OnboardingViewModel
    
    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil, vm: Binding<EditProfileViewModel>) {
        self.isOnboarding = isOnboarding
        self.title = title
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())
        self._vm = vm
    }
    
    var body: some View {
        
        let manager = dependencies.profileManager
        let userId = vm.user.userId
        
        EditOptionLayout(title: title, isSelected: $isSelected) {
            HStack {
                OptionPill(title: "Short-term", counter: $screenTracker.screen, isSelected: $isSelected) { Task { try await manager.update(userId: userId , values: [.lookingFor : "Short-term"])}
                }
                Spacer()
                OptionPill(title: "Long-term", counter: $screenTracker.screen, isSelected: $isSelected)  { Task { try await manager.update(userId: userId , values: [.lookingFor : "Long-term"])}
                }
                HStack {
                    Spacer()
                    OptionPill(title: "Undecided", counter: $screenTracker.screen, isSelected: $isSelected) { Task { try await manager.update(userId: userId , values: [.lookingFor : "Undecided"])}
                    }
                    Spacer()
                }
            }
            .customNavigation(isOnboarding: isOnboarding)
            .onAppear {isSelected = dependencies.userStore.user?.lookingFor }
        }
    }
}

//#Preview {
//    EditLookingFor(title: "Looking For")
//}
//



