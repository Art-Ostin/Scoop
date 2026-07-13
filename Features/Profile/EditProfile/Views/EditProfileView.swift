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
        NavigationStack { //As Settings appears in full screen cover
            PageScrollView(title: "Edit Profile") {
                VStack(spacing: Spacing.xxl) {
                    ProfileImages(vm: vm, selectedImage: $selectedImage)
                    PromptsView(vm: vm)
                    InfoView(vm: vm)
                    InterestsView(vm: vm)
                    PreferencesView(vm: vm)
                }
                .padding(.horizontal, Spacing.gutter)
            }
            .navigationTitle("Edit Profile")
            .colorBackground()
            .padding(.top, Spacing.titlePadding)
            .padding(.bottom, Spacing.clearance)
        }
    }
}
