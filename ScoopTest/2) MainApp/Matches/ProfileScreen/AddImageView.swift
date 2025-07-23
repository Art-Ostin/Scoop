//
//  AddImageView3.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI

@Observable class AddImageViewModel {
    
    var pickerItems: [PhotosPickerItem?] = Array(repeating: nil, count: 6)
    var selectedImages: [UIImage?] = Array(repeating: nil, count: 6)
    
    
    
    func loadImage(at index: Int) {
        guard let selection = pickerItems[index] else {return}
        Task {
            if let data = try? await selection.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {selectedImages[index] = uiImage }
                }
            }
            pickerItems[index] = nil
        }
    }
    
    
    func saveImage(at index: Int) {
        Task {
            if let data = try? await pickerItems[index]?.loadTransferable(type: Data.self) {
                guard let userId = await EditProfileViewModel.instance.user?.userId else {return}
                let path = try await StorageManager.instance.saveImage(userId: userId, data: data)
                let url = try await StorageManager.instance.getUrlForImage(path: path)
                try await ProfileManager.instance.updateImagePath(userId: userId, path: path, url: url.absoluteString)
            }
        }
    }
    
    func deleteImage(at index: Int) {
        Task {
            guard let user = await EditProfileViewModel.instance.user, let path = user.imagePath
            else {return}
            try await StorageManager.instance.deleteImage(path: path[index])
            try await ProfileManager.instance.updateImagePath(userId: user.userId, path: nil, url: nil )
        }
    }
}


struct AddImageView: View {
    
    @State private var vm = AddImageViewModel()
    @Binding var showLogin: Bool
    
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
                    PhotosPicker(
                        selection: $vm.pickerItems[idx],
                        matching: .images
                    ) {
                        Group {
                            if let img = vm.selectedImages[idx] {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image("ImagePlaceholder2")
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: vm.selectedImages[idx] != nil ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 5)
                    }
                    .onChange(of: vm.pickerItems[idx]) {
                        vm.loadImage(at: idx)
                        vm.saveImage(at: idx)
                    }
                }
            }
            ActionButton(isAuthorised: vm.selectedImages.allSatisfy {$0 != nil}, text: "Complete", onTap: {
                showLogin = false
            })
        }
    }
}

#Preview {
    AddImageView(showLogin: .constant(true))
}

