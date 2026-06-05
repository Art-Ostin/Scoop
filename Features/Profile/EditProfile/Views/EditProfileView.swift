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
    
    @State var callDismiss = false
    @Binding var selectedImage: ImageSlot?
    
    var body: some View {
        AppScrollView(title: "Edit Profile") {
            VStack(spacing: 48) {
                ImagesView(vm: vm, selectedImage: $selectedImage)
                PromptsView(vm: vm)
                InfoView(vm: vm)
                InterestsView(vm: vm)
                PreferencesView(vm: vm)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
    }
}
