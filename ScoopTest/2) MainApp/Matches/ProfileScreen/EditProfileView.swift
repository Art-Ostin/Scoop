//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI


struct EditProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State var selectedIndex: Bool = true
    
    @State var vm = EditProfileViewModel.instance
    
    @State var vm2 = InterestsOptionsViewModel()
    
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                ScrollView {
                    
                    if let user = EditProfileViewModel.instance.user {
                        Text("\(user.email)")
                        Text("\(String(describing: user.dateCreated))")
                        Text("\(user.userId)")
                        Text("\(String(describing: user.sex))")
                    }
                    
                    EditImageView()
                    
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
                ToolbarItem(placement: .topBarTrailing) {Text("Save").font(.body(14, .bold))}
            }
            .task {
                try? await vm.loadUser()
            }
        }
    }
}

#Preview {
    EditProfileView()
}

