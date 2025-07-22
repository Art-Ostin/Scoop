//
//  ProfileView.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/07/2025.
//

import SwiftUI
import FirebaseAuth


@Observable class ProfileInfoViewModel {
    
    
    private(set) var user: UserProfile? = nil
    
    func loadCurrentUser() async throws {
        
        let authDataResult = try AuthenticationManager.instance.getAuthenticatedUser()
        self.user = try await ProfileManager.instance.getProfile(userId: authDataResult.uid)
    }
}

struct ProfileInfoScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    @State var vm = ProfileInfoViewModel()
    
    var body: some View {
        
        ZStack {
            
            Color.background.ignoresSafeArea(edges: .all)
            
            VStack {
                
                Text("Hello World")
                
                if let user = vm.user {
                    Text("\(user.email)")
                    Text("\(user.userId)")
                    Text("\(String(describing: user.dateCreated))")
                }
                
                XButton()
                
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            try? await vm.loadCurrentUser()
        }
    }
}

#Preview {
    ProfileInfoScreen()
}

