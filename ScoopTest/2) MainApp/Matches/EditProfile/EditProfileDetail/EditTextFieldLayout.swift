//
//  EditNameView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct EditTextFieldLayout: View {
    
    var title: String
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @Binding var vm: EditProfileViewModel
    
    var user: CurrentUserStore {dependencies.userStore}
    
    @State var textFieldText: String = ""
    
    @FocusState private var isFocused: Bool

//    @Binding var screenTracker: OnboardingViewModel
    
    var isOnboarding: Bool
    
    init(isOnboarding: Bool,
         title: String,
         screenTracker: Binding<OnboardingViewModel>? = nil,
//         vm: Binding<EditProfileViewModel>
    ) {
        self.isOnboarding = isOnboarding
        self.title = title
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())
        self._vm = vm
    }
    
    var body: some View {
        
        
        ZStack(alignment: .topLeading) {
            
            let manager = dependencies.profileManager
            
            VStack(alignment: .leading, spacing: isOnboarding ? 72 : 108) {
                SignUpTitle(text: title)
                    .padding(.top, 96)
                    .padding(isOnboarding ? [] : .horizontal, 12)
                
                VStack(spacing: 12) {
                    
                    TextField("Type \(title) here", text: $textFieldText)
                        .frame(maxWidth: .infinity)
                        .font(.body(isOnboarding ? 24 : 40))
                        .font(.body(isOnboarding ? .medium : .bold))
                        .focused($isFocused)
                        .tint(.blue)
                    
                    RoundedRectangle(cornerRadius: 20, style: .circular)
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                        .foregroundStyle (Color.grayPlaceholder)
                }
                .padding(.horizontal, isOnboarding ? nil : 60)
                
                .onAppear {
                    if title == "Degree" {
                        textFieldText = dependencies.userStore.user?.degree ?? ""
                    } else if title == "Hometown" {
                        textFieldText = dependencies.userStore.user?.hometown ?? ""
                    } else if title == "Name" {
                        textFieldText = dependencies.userStore.user?.name ?? ""
                    }
                    isFocused = true
                }
                if isOnboarding {
                    NextButton(isEnabled: textFieldText.count > 3 , onTap: {
                        withAnimation { screenTracker.screen += 1}
                    })
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    .padding(.top, 24)
                }
            }
            .onChange(of: textFieldText) {
                if title == "Degree" {
                    Task{ try await manager.update(values: [.degree: textFieldText])}
                } else if title == "Hometown" {
                    Task{ try await manager.update(values: [.hometown: textFieldText])}
                } else if title == "Name" {
                    Task{ try await manager.update(values: [.name: textFieldText])}
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            isFocused = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .customNavigation(isOnboarding: isOnboarding)
    }
}
