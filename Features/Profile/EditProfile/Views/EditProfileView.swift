//
//  EditProfileView2.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI

struct EditProfileView: View {
    
    //Injected
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: EditProfileViewModel
    @Binding var selectedImage: ImageSlot?

    var body: some View {
        TabScrollView(title: "Edit Profile") {
            VStack(spacing: Spacing.xxl) {
                ProfileImages(vm: vm, selectedImage: $selectedImage)
                PromptsView(vm: vm)
                InfoView(vm: vm)
                InterestsView(vm: vm)
                PreferencesView(vm: vm)
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.top, Spacing.lg)
        }
    }
}
