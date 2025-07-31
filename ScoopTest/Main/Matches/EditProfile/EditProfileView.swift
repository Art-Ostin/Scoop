//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI


struct EditProfileView: View {
    
    var dep: AppDependencies
    
    init(dep: AppDependencies) {
        self.dep = dep
    }
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                ScrollView {
                    ImagesView(dependencies: dep)
                    PromptsView()
                    InfoView()
                    InterestsView(user: dep.userStore)
                    YearsView()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { NavButton(.down)}
            }
            .task {
               try? await dep.userStore.loadUser()
            }
        }
    }
}

//#Preview {
//    EditProfileView()
//}
//
