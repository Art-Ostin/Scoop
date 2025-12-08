//
//  AddImageView3.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI

struct ImageSlot: Equatable {
    var pickerItem: PhotosPickerItem?
    var path: String?
    var url: URL?
}


struct OnboardingImages: View {
    
    @Environment(\.appState) private var appState
    
    let vm: OnboardingViewModel
    @State private var imageVM: OnboardingImageViewModel

    @State var images: [UIImage?] = Array(repeating: nil, count: 6)
    private let columns = Array(repeating: GridItem(.fixed(120), spacing: 10), count: 3)
    
    init(vm: OnboardingViewModel, defaults: DefaultsManager, storage: StorageManaging, auth: AuthManaging) {
        self.vm = vm
        _imageVM = State(wrappedValue: OnboardingImageViewModel(defaults: defaults, storage: storage, auth: auth))
    }

    var body: some View {
        VStack(spacing: 36) {
            
            SignUpTitle(text: "Add 6 Photos")
                .padding(.horizontal, 12)
            
            Text("Ensure you're in all")
                .font(.body())
                .foregroundStyle(Color.grayText)
            
            LazyVGrid(columns: columns, spacing: 36) {
                ForEach(images.indices, id: \.self) { index in
                    EditPhotoCell2(image: $images[index])
                }
            }
            ActionButton(isValid: images.allSatisfy({$0 != nil}), text: "Complete") {
                Task {
                    do {
                        await imageVM.saveAll(images: images)
                        try await vm.createProfile()
                        appState.wrappedValue = .app
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 84)
        .padding(.horizontal, 24)
        .background(Color.background)
    }
}


/*
 @State var data: [Data?] = Array(repeating: nil, count: 6)
 */
