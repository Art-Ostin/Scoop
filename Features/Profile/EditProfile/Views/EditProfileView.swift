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

    @Binding var path: [EditProfileRoute]

    var body: some View {
        //One scroll view: the photo grid is a bare row so it scrolls with the sections
        List {
            ProfileImages(vm: vm)
            PromptsSection(vm: vm, path: $path)
            CoreInfo(vm: vm)
            ExtraInfo(vm: vm)
            InterestsView(vm: vm, path: $path)
            PreferencesView(vm: vm)
        }
        .environment(\.defaultMinListRowHeight, 0)
        .contentMargins(.top, 12, for: .scrollContent)
        .contentMargins(.bottom, Spacing.clearance + 24, for: .scrollContent) //clears the floating edit button
        .listBackground(color: .canvasSunken)
        .navigationTitle("Edit Profile")
    }
}


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


/*
 .plainRow(inset: 0, vertical: Spacing.sm) //flush with the section cards' edges
 */
