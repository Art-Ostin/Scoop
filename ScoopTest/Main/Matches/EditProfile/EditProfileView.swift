//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI


struct EditProfileView: View {
    
    @Environment(\.appDependencies) private var dependencies
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                ScrollView {
                    ImagesView(dependencies: dependencies)
                    PromptsView()
                    InfoView()
                    InterestsView(user: dependencies.userStore)
                    YearsView()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { NavButton(.cross)}
                ToolbarItem(placement: .topBarLeading) { NavButton(.back)}
            }
        }
    }
}

#Preview {
    EditProfileView()
}

