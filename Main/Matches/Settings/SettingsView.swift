//
//  SettingsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.appState) private var appState
    
    @State var vm: SettingsViewModel
    
    init(vm: SettingsViewModel) { self.vm = vm }
    
    
    
    var body: some View {
        
        signOutSection
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Settings")
    }
}

extension SettingsView {
    
    private var signOutSection: some View {
        
        CustomList(title: vm.user.email) {
            Text("Sign Out")
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .onTapGesture {
                    vm.signOut()
                    appState.wrappedValue = .login
                }
            softDivider
                .padding(.trailing)
            
            Text("Delete Account")
                .frame(maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .foregroundStyle(.accent)
        }
    }
    
    private var softDivider: some View {
        Rectangle()
            .frame(height: 1)
            .frame(maxWidth:.infinity)
            .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
            .padding(.horizontal, 24)
    }
}



