//
//  AddImageView3.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI

struct AddImageView: View {
    
    @Environment(\.appState) private var appState
    
    @State private var vm: EditProfileViewModel
    @State var images: [UIImage] = Array(repeating: UIImage(named: "ImagePlaceholder") ?? UIImage(), count: 6)
    
    private let columns = Array(repeating: GridItem(.fixed(120), spacing: 10), count: 3)
    init(vm: EditProfileViewModel) { self._vm = State(initialValue: vm) }
    
    var body: some View {
        VStack(spacing: 36) {
            SignUpTitle(text: "Add 6 Photos")
                .padding(.horizontal, -10)

            Text("Ensure you're in all")
                .font(.body())
                .foregroundStyle(Color.grayText)
            
            LazyVGrid(columns: columns, spacing: 36) {
                ForEach(0..<6) {idx in
                    EditPhotoCell(picker: $vm.slots[idx].pickerItem, image: vm.images[idx]) {
                        try await vm.changeImage(at: idx)
                    }
                }
            }
            
            ActionButton(isValid: vm.isValid, text: "Complete") {
                appState.wrappedValue = .app
                vm.s.showProfiles = false
            }
        }
        .task { await vm.assignSlots() }
    }
}
