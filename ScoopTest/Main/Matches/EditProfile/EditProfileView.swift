//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI


struct EditProfileView: View {
    
    @Binding var vm: EditProfileViewModel
    
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                ScrollView {
                    ImagesView(vm: EditImageViewModel(userManager: vm.userManager, cacheManager: vm.cachManager, storageManager: vm.storageManager))
                    PromptsView(vm: $vm)
                    InfoView()
                    InterestsView(vm: $vm)
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
        }
    }
}
