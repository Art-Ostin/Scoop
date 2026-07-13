//
//  SettingsContainer.swift
//  Scoop
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct SettingsContainer: View {
    @Environment(\.dismiss) private var dismiss
    @State var vm: SettingsViewModel
    
    init(vm: SettingsViewModel) { self.vm = vm }

    var body: some View {
        NavigationStack { //As Settings appears in full screen cover
            ScrollView {
                VStack(spacing: Spacing.xl) {
                        meetTheTeam
                        keySettingsSection
                        PreferredMapsView(vm: vm)
                        signOutSection
                }
                .toolbar { DismissToolbarItem(type: .cross, isLeading: false) }
                .padding(Spacing.lg)
                .navigationBarBackButtonHidden()
            }
            .navigationTitle("Settings")
            .colorBackground()
            .padding(.top, Spacing.titlePadding)
            .padding(.bottom, Spacing.clearance)

            
            
            
        }
    }
}

extension SettingsContainer {
    
    private var signOutSection: some View {
        CustomList(title: vm.user.email) {
            Text("Sign Out")
                .font(.body(15, .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .onTapGesture {

                    vm.session.appState = .login

                    //Fixes crash -> only sign user out when on login screen, as if not userProfile crashes app.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        vm.signOut()
                    }
                }
            softDivider
                .padding(.trailing)
            
            Text("Delete Account")
                .font(.body(15, .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .foregroundStyle(.accent)
        }
    }
    

    
    private var meetTheTeam: some View {
        CustomList(title: "Meet the Teem") {
            
            customRow(text: "Alice Godbout", role: "Software Engineer")
            
            customDivider
            
            customRow(text: "Genevieve Jakeway", role: "Digital Artist")
            
            customDivider
            
            customRow(text: "William Potter", role: "Software Engineer")
            
            customDivider
            
            customRow(text: "William Lane", role: "UI/UX Designer")
            
            customDivider
            
            customRow(text: "Arthur Ostin", role: "Founder/Software Engineer")
        }
    }
    
    
    private var customDivider: some View {
        Rectangle()
            .frame(height: 1)
            .frame(maxWidth:.infinity)
            .foregroundStyle(Color.border)
            .padding(.leading, Spacing.md)
    }
    
    private var keySettingsSection: some View {
        
        CustomList(title: "legal") {
            
            customRow(text: "Privacy Policy")
            
            customDivider
            
            customRow(text: "Terms of Service")

            customDivider
            
            customRow(text: "Download My Data (Beta)")
        }
        .font(.body(17, .medium))
        .foregroundStyle(Color.textPrimary)
    }
    
    private var softDivider: some View {
        Rectangle()
            .frame(height: 1)
            .frame(maxWidth:.infinity)
            .foregroundStyle(Color.border)
            .padding(.horizontal, Spacing.margin)
    }
    
    private func customRow(text: String, role: String? = "") -> some View {
        HStack {
            (
                Text(text)
                +
                Text("   \(role ?? "") ")
                    .foregroundStyle(Color.textTertiary)
                    .font(.body(15, .regular))
            )
            Spacer()
            Image(systemName: "chevron.right")
                .font(.body(15, .medium))
        }
        .padding(.horizontal, Spacing.md)
        .font(.body(15, .bold))
        .frame(height: 40)
    }
}
