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
        
        if let user = dep.userManager.user {
            Group {
                if isView {
                    ProfileView(profile: user, showInviteButton: false, dep: dep)
                        .transition(.move(edge: .leading))
                } else {
                    EditProfileView(dep: dep)
                        .transition(.move(edge: .trailing))
                }
            }
            .overlay(alignment: .bottom) {
                EditProfileButton(isView: $isView)
                    .padding(.bottom)
                    .onTapGesture {
                        Task { try await dep.userManager.loadUser() }
                        withAnimation{ isView.toggle()}
                    }
            }
        }
    }
}

#Preview {
    EditProfileContainer()
}
