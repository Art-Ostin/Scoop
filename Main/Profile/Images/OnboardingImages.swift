//
//  AddImageView3.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI

struct SelectedImage: Identifiable {
    let id = UUID()
    let index: Int
    var image: UIImage
    var imageData: Data?
    var pickerItem: PhotosPickerItem?
}

struct OnboardingImages: View {
    
    @Environment(\.appState) private var appState
    @Environment(\.dismiss) private var dismiss
    
    let vm: OnboardingViewModel
    @State private var imageVM: OnboardingImageViewModel

    @State var images: [UIImage?] = Array(repeating: nil, count: 6)


    @State var selectedImage: SelectedImage? = nil
    
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
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(images.indices, id: \.self) { index in
                    OnboardingPhotoCell(selectedImage: $selectedImage, index: index, image: $images[index])
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
        .fullScreenCover(item: $selectedImage) { localImage in
            ProfileImagesEditing(importedImage: localImage) { updatedImage in
                images[updatedImage.index] = updatedImage.image
//                dismiss()
            }
        }
    }
}

extension OnboardingImages {
    
    private var onboardingImagePlaceholder: some View {
        Image("ImagePlaceholder")
            .resizable()
            .scaledToFill()
            .frame(width: 110, height: 110)
    }
}
