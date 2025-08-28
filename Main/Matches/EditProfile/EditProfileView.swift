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
        
        NavigationStack {
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
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.updatedFields.isEmpty && vm.updatedFieldsArray.isEmpty && vm.updatedImages.isEmpty {
                        NavButton(.down)
                    } else {
                        Button("SAVE") {
                            dismiss()
                            Task {
                                try await vm.saveUser()
                                try await vm.saveUserArray()
                                try await vm.saveUpdatedImages()
                                print("completed")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !vm.updatedFields.isEmpty || !vm.updatedImages.isEmpty || !vm.updatedFieldsArray.isEmpty {
                        NavButton(.cross)
                    }
                }
            }
        }
    }
}
