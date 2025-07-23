//
//  AddImageView3.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//
import SwiftUI
import PhotosUI


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
                    PhotoCell(picker: $vm.pickerItems[idx], image: vm.selectedImages[idx]) {
                        vm.loadImage(at: idx)
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



struct PhotoCell: View {
    
    @Binding var picker: PhotosPickerItem?
    let image:  UIImage?
    let loadImage: () -> Void
    
    var body : some View {
        PhotosPicker(selection: $picker, matching: .images) {
            
            Group {
                if let img = image {
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
            .shadow(color: image != nil ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 5)
            
        }
        .onChange(of: picker) {
            loadImage()
        }
    }
}
