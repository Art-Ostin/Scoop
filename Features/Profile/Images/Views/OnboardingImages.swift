//
//  AddImageView3.swift
//  Scoop
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI


struct OnboardingImages: View {
    
    //Injected
    @Environment(AppDependencies.self) private var dep
    @Environment(\.dismiss) private var dismiss
    let vm: OnboardingViewModel

    //Local view state
    @State private var imageVM: ProfileImagesViewModel
    @State private var images: [UIImage?] = Array(repeating: nil, count: 6)
    @State private var selectedImage: ImageSlot? = nil
    @State private var showSavingScreen: Bool = false
    private let columns = Array(repeating: GridItem(.fixed(120), spacing: 10), count: 3)

    init(vm: OnboardingViewModel, defaultsManager: DefaultsManaging, storageService: StorageServicing, authService: AuthServicing) {
        self.vm = vm
        _imageVM = State(wrappedValue: ProfileImagesViewModel(defaults: defaultsManager, storageService: storageService, auth: authService))
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            
            SignUpTitle(text: "Add 6 Photos")
                .padding(.horizontal, 12)
            
            Text("Ensure you're in all")
                .font(.body())
                .foregroundStyle(Color.textTertiary)
            
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(images.indices, id: \.self) { index in
                    OnboardingPhotoCell(selectedImage: $selectedImage, index: index, image: $images[index])
                }
            }
            ActionButton(text: "Complete", isValid: images.allSatisfy({$0 != nil})) {
                showSavingScreen = true
                Task {
                    do {
                         await imageVM.saveAll(images: images)
                         try await vm.createProfile()
                         dep.session.appState = .app
                    } catch {
                        showSavingScreen = false // TODO: surface the failure via InAppNotificationCenter
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 84)
        .padding(.horizontal, 24)
        .background(Color.appCanvas)
        .fullScreenCover(item: $selectedImage) {localImage in
            ProfileImageEditor(importedImage: localImage) { updatedImage in
                images[updatedImage.index] = updatedImage.image
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showSavingScreen)
        .overlay {
            if showSavingScreen {
                ZStack {
                    OnboardingLoadingScreen()
                }
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
                .background(Color.appCanvas)
                .onTapGesture {
                    showSavingScreen = false
                }
            }
        }
        .toolbar(showSavingScreen ? .hidden : .visible, for: .navigationBar)
    }
}
