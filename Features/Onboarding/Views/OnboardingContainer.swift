//
//  NewOnboardingContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct OnboardingContainer: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.flowMode) private var mode
    let vm: OnboardingViewModel
    let storage: StorageServicing
    @State private var enlargenStep: Bool = false
    @State private var showSaved: Bool = false
    
    
    
    @ViewBuilder
    private var stepView: some View {
            switch vm.onboardingStep {
            case 0: OnboardingSex(vm: vm)
            case 1: OnboardingOption(vm: vm, field: .attractedTo)
            case 2: OnboardingOption(vm: vm, field: .lookingFor)
            case 3: OnboardingOption(vm: vm, field: .year)
            case 4: OnboardingHeight(vm: vm)
            case 5: OnboardingLifestyle(vm: vm)
            case 6: OnboardingInterests(vm: vm)
            case 7: OnboardingNationality(vm: vm)
            case 8: OnboardingTextField(vm: vm, field: .hometown)
            case 9: OnboardingTextField(vm: vm, field: .degree)
            case 10: OnboardingPrompt(vm: vm, promptIndex: 0)
            case 11: OnboardingPrompt(vm: vm, promptIndex: 1)
            case 12: OnboardingImages(vm: vm, defaultsManager: vm.defaultManager, storageService: storage, authService: vm.authService)
            default: EmptyView()
        }
    }
    
    @State private var bounce = false
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                stepView
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {dismissButton}
                        ToolbarItem(placement: .topBarLeading) {if vm.onboardingStep > 0 {backButton}}
                        ToolbarItem(placement: .principal) {saveAndStepMarker}
                        .hideSharedBackgroundIfAvailable()
                    }
                    .transition(vm.transitionStep)
                    .animation(.easeInOut(duration: 0.3), value: showSaved)
                    .onChange(of: vm.onboardingStep) { oldValue, newValue in
                        flashSavedIndicator(oldValue, newValue)
                    }
            }
            .navigationBarTitleDisplayMode(.inline) //Fixes Bug: decreases the top container pushing all the content down
        }
    }
}


extension OnboardingContainer {
    
    private var saveAndStepMarker: some View {
        ZStack {
            onboardingStepTracker
            saveButton
        }
        .animation(.easeInOut(duration: 0.25), value: showSaved)
    }
    
    private var saveButton: some View {
        HStack(spacing: 12) {
            Text("Saved")
                .font(.body(14, .bold))
                .foregroundStyle(Color(red: 0.16, green: 0.65, blue: 0.27))
            
            Image("GreenTick")
        }
        .opacity(showSaved ? 1 : 0)
    }
    
    private var onboardingStepTracker: some View {
        Text("\(vm.onboardingStep)/\(12)")
            .font(.body(12, .bold))
            .foregroundStyle(bounce ? .accent : .accent)
            .opacity(showSaved ? 0 : 1)
    }
    
    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.body(16, .bold))
                .padding(24)
                .contentShape(Rectangle())
                .padding(-24)
        }
    }
    
    private var backButton: some View {
        Button {
            vm.goBackStep()
        } label: {
            Image(systemName: "chevron.left")
                .font(.body(16, .bold))
                .frame(width: 30, height: 60) //Frame Solves a bug for quick dismissing
                .contentShape(Rectangle())
        }
    }
    
    private func flashSavedIndicator(_ oldValue: Int,_ newValue: Int) {
        guard oldValue != newValue else { return }
        showSaved = true
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            showSaved = false
        }
    }
}


extension ToolbarContent {

    
    @ToolbarContentBuilder
    func hideSharedBackgroundIfAvailable() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
