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
    @Binding var navigationPath: [EditProfileRoute]
    @Binding var selectedImage: ImageSlot?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            CustomTabPage(page: .EditProfile, TabAction: $callDismiss) {
                    ImagesView(vm: vm, selectedImage: $selectedImage)
                    PromptsView(vm: vm)
                    InfoView(vm: vm)
                    InterestsView(vm: vm)
                    PreferencesView(vm: vm)
            }
            .navigationDestination(for: EditProfileRoute.self) { route in
                switch route {
                case .prompt(let index):
                    EditPrompt(vm: vm, promptIndex: index)
                case .interests:
                    EditInterests(vm: vm)
                case .textField(let field):
                    EditTextfield(vm: vm, field: field)
                case .option(let field):
                    EditOption(vm: vm, field: field)
                case .height:
                    EditHeight(vm: vm)
                case .nationality:
                    EditNationality(vm: vm)
                case .lifestyle:
                    EditLifestyle(vm: vm)
                case .myLifeAs:
                    EditMyLifeAs(vm: vm)
                case .languages:
                    EditLanguages(vm: vm)
                case .desiredAgeRange:
                    EditPreferredYears(vm: vm)
                }
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
