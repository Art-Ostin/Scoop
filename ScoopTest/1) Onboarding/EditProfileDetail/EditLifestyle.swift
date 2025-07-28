//
//  VicesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct EditLifestyle: View {
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
//    @Binding var vm: EditProfileViewModel
    
    @State var isSelectedDrinking: String?
    @State var isSelectedSmoking: String?
    @State var isSelectedMarijuana: String?
    @State var isSelectedDrugs: String?
    
    let title: String?
    
    @Binding var screenTracker: OnboardingViewModel
    
    var isOnboarding: Bool
    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil /*vm: Binding<EditProfileViewModel>)*/ ){
        self.isOnboarding = isOnboarding
        self.title = title
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())
//        self._vm = vm
    }
    
        
    var body: some View {
        
//        let user = vm.user
        let manager = dependencies.profileManager
        
        
        VStack(spacing: 48) {
            vicesOptions(title: "Drinking", isSelected: $isSelectedDrinking)
            vicesOptions(title: "Smoking", isSelected: $isSelectedSmoking)
            vicesOptions(title: "Marijuana", isSelected: $isSelectedMarijuana)
            vicesOptions(title: "Drugs", isSelected: $isSelectedDrugs)
        }
        .padding(.horizontal)
        .customNavigation(isOnboarding: isOnboarding)
        .onAppear {
            let user = dependencies.userStore.user
            isSelectedDrinking = user?.drinking
            isSelectedSmoking = user?.smoking
            isSelectedMarijuana = user?.marijuana
        }
        .onChange(of: isSelectedDrinking) {
            nextScreen()
            Task{ try await manager.update(values: [.drinking : isSelectedDrinking ?? ""])}
        }
        .onChange(of: isSelectedSmoking) {
            nextScreen()
            Task{ try await manager.update(values: [.smoking : isSelectedSmoking ?? ""])}
        }
        .onChange(of: isSelectedMarijuana) {
            nextScreen()
            Task{try await manager.update(values: [.marijuana : isSelectedMarijuana ?? ""])}
        }
        .onChange(of: isSelectedDrugs) {
            nextScreen()
            Task{try await manager.update(values: [.drugs : isSelectedDrugs ?? ""])}
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

//#Preview {
//    EditLifestyle()
//}



//let user = dependencies.userStore.user
//let currentlyInFirebase = user?.nationality?.contains(country) == true
//if currentlyInFirebase {
//    vm.removeNationality(nationality: country)
//} else if selectedCountries.count < 3 {
//    vm.updateNationality(nationality: country)
//}
