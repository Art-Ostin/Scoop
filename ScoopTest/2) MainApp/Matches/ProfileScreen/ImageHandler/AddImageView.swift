//
//  AddImageView3.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI


@MainActor
struct AddImageView: View {
    
    @State private var vm = ImageViewModel()
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
                    PhotoCell2(picker: $vm.pickerItems[idx], urlString: vm.imageURLs[idx], image: vm.selectedImages[idx]) {
                        vm.loadImage(at: idx)
                    }
                }
            }
            ActionButton(isAuthorised: vm.selectedImages.allSatisfy {$0 != nil}, text: "Complete", onTap: {
                showLogin = false
            })
        }
        .task {
            try? await EditProfileViewModel.instance.loadUser()
            vm.seedFromCurrentUser()
        }
    }
}

#Preview {
    AddImageView(showLogin: .constant(true))
}

//PhotoCell2(picker: $vm.pickerItems[idx], urlString: vm.imageURLs[idx]) {
//    vm.loadImage(at: idx)
//}

//PhotoCell(picker: $vm.pickerItems[idx], image: vm.selectedImages[idx]) {
//    vm.loadImage(at: idx)
//}
