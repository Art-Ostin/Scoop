//
//  VicesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct EditLifestyle: View {
    
    @State var isSelectedDrinking: String? = CurrentUserStore.shared.user?.drinking
    @State var isSelectedSmoking: String? = CurrentUserStore.shared.user?.smoking
    @State var isSelectedMarijuana: String? = CurrentUserStore.shared.user?.marijuana
    @State var isSelectedDrugs: String? = CurrentUserStore.shared.user?.drugs
        
    let title: String?
    let firebase = EditProfileViewModel.instance
    
    @Binding var screenTracker: OnboardingViewModel
    var isOnboarding: Bool
    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil) {
        self.isOnboarding = isOnboarding
        self.title = title
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())}
    
        
    var body: some View {
        
        VStack(spacing: 48) {
            vicesOptions(title: "Drinking", isSelected: $isSelectedDrinking)
            vicesOptions(title: "Smoking", isSelected: $isSelectedSmoking)
            vicesOptions(title: "Marijuana", isSelected: $isSelectedMarijuana)
            vicesOptions(title: "Drugs", isSelected: $isSelectedDrugs)
        }
        .padding(.horizontal)
        .customNavigation(isOnboarding: isOnboarding)
        .onChange(of: isSelectedDrinking) {
            nextScreen()
            firebase.updateDrinking(drinking: isSelectedDrinking ?? "")
        }
        .onChange(of: isSelectedSmoking) {
            nextScreen()
            firebase.updateSmoking(smoking: isSelectedSmoking ?? "" )
        }
        .onChange(of: isSelectedMarijuana) {
            nextScreen()
            firebase.updateMarijuana(marijuana: isSelectedMarijuana ?? "")
        }
        .onChange(of: isSelectedDrugs) {
            nextScreen()
            firebase.updateDrugs(drugs: isSelectedDrugs ?? "")
        }
    }

    private func vicesOptions(title: String, isSelected: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.title(28))
            HStack {
                OptionPill(title: "Yes", width: 75, isSelected: isSelected, onTap: {})
                Spacer()
                OptionPill(title: "No", width: 75, isSelected: isSelected, onTap: {})
                Spacer()
                OptionPill(title: "Occasionally", isSelected: isSelected, onTap: {} )
            }
        }
    }
    
    private func nextScreen() {
        guard isOnboarding,
              isSelectedDrinking != nil,
              isSelectedSmoking != nil,
              isSelectedMarijuana != nil,
              isSelectedDrugs != nil else
        {return }
        withAnimation {
            screenTracker.screen += 1
        }
    }
}

#Preview {
    EditLifestyle()
}



