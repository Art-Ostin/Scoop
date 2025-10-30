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
    @Environment(\.flowMode) private var mode
    
    @State private var vm: OnboardingViewModel
    @State var images: [UIImage] = Array(repeating: UIImage(named: "ImagePlaceholder") ?? UIImage(), count: 6)
    
    private let columns = Array(repeating: GridItem(.fixed(120), spacing: 10), count: 3)
    
    init(vm: OnboardingViewModel) { self._vm = State(initialValue: vm) }
    
    
    
    var body: some View {
        VStack(spacing: 36) {
            
            SignUpTitle(text: "Add 6 Photos")
                .padding(.horizontal, 12)
            
            Text("Ensure you're in all")
                .font(.body())
                .foregroundStyle(Color.grayText)
            
            LazyVGrid(columns: columns, spacing: 36) {
                ForEach(0..<6) { idx in
                    EditPhotoCell(picker: $vm.slots[idx].pickerItem, image: vm.images[idx]) {
                        try await vm.changeImage(at: idx)
                    }
                }
            }
            
            ActionButton(isValid: true, text: "Complete") {
                Task {
                    do {
                        try await vm.createProfile()
                        appState.wrappedValue = .app
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .flowNavigation()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
        .padding(.top, 84)
        .padding(.horizontal, 24)
    }
}
