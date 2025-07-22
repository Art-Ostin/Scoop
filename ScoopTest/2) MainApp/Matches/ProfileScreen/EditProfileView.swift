//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI


@Observable class EditProfileViewModel {
    
    
    
    var nameTextField: String = "Arthur"
    var hometownTextField: String = "London"
    var degreeTextField: String = "Politics"
    
    
    
    private(set) var user: UserProfile? = nil
    
    func loadUser() async throws {
            let AuthUser = try AuthenticationManager.instance.getAuthenticatedUser()
        
        self.user = try await ProfileManager.instance.getProfile(userId: AuthUser.uid)
    }
    
}

struct EditProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State var selectedIndex: Bool = true

    @State var vm = EditProfileViewModel()
    @State var vm2 = InterestsOptionsViewModel()

        
    var body: some View {

        NavigationStack {
            ZStack {
                ScrollView {
                    
                    if let user = vm.user {
                        Text("\(user.email)")
                        Text("\(String(describing: user.dateCreated))")
                        Text("\(user.userId)")
                        Text("\(user.userId)")
                    }
                    
                    
                    EditImageView()
                    
                    PromptsView()
                    
                    InfoView(vm: $vm)
                    
                    InterestsView()

                    YearsView()
                    
                    
                }
                ViewProfileButton()
            }
            .navigationTitle("Profile")
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { XButton {dismiss()} }
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

