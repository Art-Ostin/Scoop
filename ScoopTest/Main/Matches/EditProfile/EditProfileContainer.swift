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
            ZStack(alignment: .bottom) {
                if isView {
                    EditProfileView(dep: dep)
                } else {
                    ProfileView(profile: user)
                }
                
                EditProfileButton(isView: $isView)
                    .padding(.bottom)
            }
            
        }
    }
}


#Preview {
    EditProfileContainer()
}
