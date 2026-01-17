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
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            CustomTabPage(page: .EditProfile, TabAction: $callDismiss) {
                    ImagesView(vm: vm)
                    PromptsView(vm: vm)
                    InfoView(vm: vm)
                    InterestsView(vm: vm)
                    YearsView()
            }
        }
    }
}

/*
ZStack {
     ScrollView {
         ImagesView(vm: vm)
         PromptsView(vm: vm)
         InfoView(vm: vm)
         InterestsView(vm: vm)
         YearsView()
     }
 }
 */
