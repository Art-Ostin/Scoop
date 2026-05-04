//
//  SettingsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appState) private var appState
    @State var vm: SettingsViewModel
    

    init(vm: SettingsViewModel) { self.vm = vm }

    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                meetTheTeam

                keySettingsSection

                PreferredMapView(vm: vm)

                signOutSection
            }
            .navigationTitle("Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar { DismissToolbarItem() }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .background(Color.background.ignoresSafeArea())
    }
}

extension SettingsView {
    
    private var signOutSection: some View {
        CustomList(title: vm.user.email, usesContainerWidth: false) {
            Text("Sign Out")
                .font(.body(15, .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .onTapGesture {
                    
                    appState.wrappedValue = .login

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
        CustomList(title: "Meet the Teem", usesContainerWidth: false) {
            
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
            .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
            .padding(.leading, 16)
    }
    
    
    
    
    
    private var keySettingsSection: some View {
        
        CustomList(title: "legal", usesContainerWidth: false) {
            
            customRow(text: "Privacy Policy")
            
            customDivider
            
            customRow(text: "Terms of Service")

            customDivider
            
            customRow(text: "Download My Data (Beta)")
        }
        .font(.body(17, .medium))
        .foregroundStyle(Color.black)
    }
    
    
    
    private var softDivider: some View {
        Rectangle()
            .frame(height: 1)
            .frame(maxWidth:.infinity)
            .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
            .padding(.horizontal, 24)
    }
    
    private func customRow(text: String, role: String? = "") -> some View {
        HStack {
            (
                Text(text)
                +
                Text("   \(role ?? "") ")
                    .foregroundStyle(Color.grayText)
                    .font(.body(15, .regular))
            )
            Spacer()
            Image(systemName: "chevron.right")
                .font(.body(15, .medium))
        }
        .padding(.horizontal, 16)
        .font(.body(15, .bold))
        .frame(height: 40)
    }
}
