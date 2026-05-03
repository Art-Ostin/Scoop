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
                
                preferredMapType
                
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
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .onTapGesture {
                    withAnimation { appState.wrappedValue = .login }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        vm.signOut()
                    }) //Fixes Bug gives time for the session to close (and not cause fatal error)
                }
            softDivider
                .padding(.trailing)
            
            Text("Delete Account")
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .foregroundStyle(.accent)
        }
    }
    
    
    private var preferredMapType: some View {
        CustomList(title: "Preferred map", usesContainerWidth: false) {
            HStack {
                mapOption(isApple: false, isSelected: false)
                Spacer()
                mapOption(isApple: true, isSelected: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private func mapOption(mapType: PreferredMapType) -> some View {
        let isAppleMaps = mapType == .appleMaps
        let isSelected = mapType ==
        Button {
            
        } label: {
            
        }
        
        
        HStack(spacing: 10) {
            Image(map)
                .opacity(isSelected ? 1 : 0.4)
            Text(isApple ? "Apple Maps" : "Google Maps")
        }
        .frame(width: 148, height: 44, alignment: .center)
        .font(.body(15, .bold))
        .stroke(20, lineWidth: isSelected ? 0 : 1, color: Color.grayPlaceholder)
        .stroke(20, lineWidth: isSelected ? 1 : 0, color: Color.blue)
        .foregroundStyle(isSelected ? Color.black : Color.grayPlaceholder)
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

/*
 let mapStroke = LinearGradient(
     colors: [
         Color(red: 0.259, green: 0.522, blue: 0.957),
         Color(red: 0.204, green: 0.659, blue: 0.325),
         Color(red: 0.984, green: 0.737, blue: 0.016),
         Color(red: 0.918, green: 0.263, blue: 0.208)
     ],
     startPoint: UnitPoint(x: 0.0, y: 0.0),
     endPoint: UnitPoint(x: 0.30, y: 1.0)
 )

 */
