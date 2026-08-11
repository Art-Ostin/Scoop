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

    @Binding var path: [EditProfileRoute]

    var body: some View {
        //One scroll view: the photo grid is a bare row so it scrolls with the sections
        List {
            ProfileImages(vm: vm, selectedImage: $selectedImage)
                .plainRow(inset: 0, vertical: Spacing.sm) //flush with the section cards' edges
            PromptsSection(vm: vm, path: $path)
            CoreInfo(vm: vm)
            ExtraInfo(vm: vm)
            InterestsView(vm: vm, path: $path)
            PreferencesView(vm: vm)
        }
        .contentMargins(.bottom, Spacing.clearance, for: .scrollContent) //clears the floating edit button
        .listBackground(color: .canvasSunken)
        .navigationTitle("Edit Profile")
    }
}

//Renders a section that builds its own chrome as one bare, full-width list row
private extension View {
    func plainRow(inset: CGFloat = Spacing.gutter, vertical: CGFloat = 0) -> some View {
        listRowInsets(EdgeInsets(top: vertical, leading: inset, bottom: vertical, trailing: inset))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}


//Swaps the List's system chrome for a flat canvas: no grouped backdrop, no white row cards
private extension View {
    func listBackground(color: Color) -> some View {
        scrollContentBackground(.hidden)
            .background(color)
            .listRowBackground(Color.clear)
    }
}
