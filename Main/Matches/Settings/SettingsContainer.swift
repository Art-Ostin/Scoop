//
//  SettingsContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 27/08/2025.
//

import SwiftUI

struct SettingsContainer: View {
    
    @State var vm: SettingsViewModel
    
    init(vm: SettingsViewModel) { self.vm = vm }
    
    var body: some View {
        VStack {
            ActionButton(text: "Sign Out") {vm.signOut()}
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            NavButton(.cross)
        }
    }
}




//#Preview {
//    SettingsContainer()
//}
