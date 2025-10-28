//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: EditProfileViewModel
    
    var body: some View {
        ZStack {
            ScrollView {
                ImagesView(vm: vm)
                PromptsView(vm: vm)
                InfoView(vm: vm)
                InterestsView(vm: vm)
                YearsView()
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden()
        .background(Color.background)
    }
}
