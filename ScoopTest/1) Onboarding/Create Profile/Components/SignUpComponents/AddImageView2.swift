//
//  AddImageView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//



import SwiftUI
import PhotosUI



@Observable class AddImageViewModel2 {
    
    
    var photoSelections: [PhotosPickerItem?] = Array(repeating: nil, count: 6)
    var selectedImages: [UIImage?] = Array(repeating: nil, count: 6)
    
    func loadImage(at index: Int) {
        
        guard let selection = photoSelections[index] else {return}
        Task {
            if let data = try? await selection.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        selectedImages[index] = uiImage
                    }
                }
            }
            await MainActor.run {
                photoSelections[index] = nil
            }
        }
    }
}



struct AddImageView2: View {
    
    @State var vm = AddImageViewModel2()
    
    var body: some View {
        
        VStack(spacing: 36) {
            SignUpTitle(text: "Add 6 Photos")
            
            Text("Ensure you're in all")
                .font(.body())
                .foregroundStyle(Color.grayText)
            
            imagePickerGrid
            
            ActionButton(text: "Complete", onTap: {}, isAuthorised: vm.selectedImages.allSatisfy{$0 != nil})
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    AddImageView2()
}


extension AddImageView2 {
    
    private var imagePickerGrid: some View {
        VStack(spacing: 36) {
            ForEach(0..<2) {row in
                HStack {
                    ForEach(0..<3) {col in
                        let idx = row * 3 + col
                        
                        PhotosPicker(
                            selection: Binding (
                                get: {vm.photoSelections[idx]},
                                set: { new in
                                    vm.photoSelections[idx] = new
                                    vm.loadImage(at: idx)
                                }
                            ),
                            matching: .images) {
                                Group {
                                    if let image = vm.selectedImages[idx] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
                                            .overlay(alignment: .topTrailing){
                                                ChangeImageIcon()
                                            }
                                    } else {
                                        Image("ImagePlaceholder2")
                                    }
                                }
                            }
                        if col < 2 {
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
