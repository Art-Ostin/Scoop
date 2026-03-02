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
        VStack(spacing: 36) {
            meetTheTeam
            
            keySettingsSection
            
            signOutSection
        }
        .navigationTitle("Settings")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { CloseToolBar() }
        .padding(.horizontal, 24)
    }
}

extension SettingsView {
    
    private var signOutSection: some View {
        CustomList(title: vm.user.email, usesContainerWidth: false) {
            Text("Sign Out")
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .onTapGesture {
                    withAnimation { appState.wrappedValue = .login }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        vm.signOut()
                    }) //gives time for the session to close (and not cause fatal error) 
                }
            softDivider
                .padding(.trailing)
            
            Text("Delete Account")
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
