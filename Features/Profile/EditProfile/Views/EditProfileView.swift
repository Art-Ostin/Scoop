//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI

enum EditProfileRoute: Hashable {
    case prompt(Int)
    case interests
    case textField(TextFieldOptions)
    case languages
    case option(OptionField)
    case height
    case nationality
    case lifestyle
    case myLifeAs
    case desiredAgeRange
}

struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: EditProfileViewModel

    @State var callDismiss = false
    @Binding var selectedImage: ImageSlot?

    var body: some View {
        CustomTabPage(page: .editProfile, tabAction: $callDismiss) {
            ImagesView(vm: vm, selectedImage: $selectedImage)
            PromptsView(vm: vm)
            InfoView(vm: vm)
            InterestsView(vm: vm)
            PreferencesView(vm: vm)
        }
    }
}
