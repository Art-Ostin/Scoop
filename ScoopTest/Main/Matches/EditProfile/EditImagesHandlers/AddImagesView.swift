//
//  AddImageView3.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI


struct AddImageView: View {
    
    @State private var vm: EditImageViewModel
    
    @Environment(\.appDependencies) private var dependencies
    @Binding var showLogin: Bool
    
    init(dep: AppDependencies, showLogin: Binding<Bool>) {
        self._vm = State(initialValue: EditImageViewModel(dep: dep))
        self._showLogin = showLogin
    }

    private let columns = Array(repeating: GridItem(.fixed(120), spacing: 10), count: 3)
    var body: some View {
        VStack(spacing: 36) {
            SignUpTitle(text: "Add 6 Photos")
                .padding(.horizontal, -10)

            Text("Ensure you're in all")
                .font(.body())
                .foregroundStyle(Color.grayText)

            LazyVGrid(columns: columns, spacing: 36) {
                ForEach(0..<6) {idx in
                    EditPhotoCell(picker: $vm.slots[idx].pickerItem, url: vm.slots[idx].url) {
                        vm.changeImage(at: idx)
                    }
                }
            }
            ActionButton(isValid: vm.slots.allSatisfy {$0.url != nil}, text: "Complete", onTap: {
                showLogin = false
            })
        }
        .task {
            try? await dependencies.userStore.loadUser()
            vm.assingImages()
        }
    }
}
