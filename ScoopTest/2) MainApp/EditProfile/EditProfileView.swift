//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI


struct EditProfileView: View {
    
    
    @State var vm: EditProfileViewModel
    
    
    init(profile: UserProfile) {
        self._vm = State(initialValue: EditProfileViewModel(currentUser: <#T##CurrentUserStore#>, profile: <#T##any ProfileManaging#>))
    }

    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                ScrollView {
                    ImagesView(dependencies: dependencies)
                    PromptsView()
                    InfoView()
                    InterestsView()
                    YearsView()
                }
                ViewProfileButton()
            }
            .navigationTitle("Profile")
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { XButton()}
            }
        }
    }
}

#Preview {
    EditProfileView()
}

