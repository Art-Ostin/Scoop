//
//  EditProfileContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI

struct EditProfileContainer: View {
    
    @Environment(\.appDependencies) var dep
    @State var isView: Bool = true
    
    
    var body: some View {
        
        if let user = dep.userStore.user {
            
            Group {
                if isView {
                    ProfileView(profile: user)
                } else {
                    EditProfileView(dep: dep)
                }
            }
            .overlay(alignment: .bottom) {
                EditProfileButton(isView: $isView)
                    .padding(.bottom)
            }
        }
    }
}


#Preview {
    EditProfileContainer()
}
