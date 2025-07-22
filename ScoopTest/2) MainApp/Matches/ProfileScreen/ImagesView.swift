//
//  EditImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI
import PhotosUI

struct EditImageView: View {
    
    @State var vm = AddImageViewModel()
    @State var isOnboarding: Bool = false
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
            
            CustomList {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<6, id: \.self) {idx in
                        PhotosPicker(
                            selection: vm.photoPickerBinding(at: idx),matching: .images) {
                                if let image = vm.selectedImages[idx] {
                                    ImageContainer(image: image)
                                }
                            }
                    }
                }
                .padding(.horizontal, 10)
                .onAppear {
                    if !isOnboarding {
                        vm.selectedImages = [
                            UIImage(named: "Image1"),
                            UIImage(named: "Image2"),
                            UIImage(named: "Image3"),
                            UIImage(named: "Image4"),
                            UIImage(named: "Image5"),
                            UIImage(named: "Image6")
                        ]
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
    }
}

#Preview {
    EditImageView()
}


struct ImageContainer: View {
    
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 1)
            .overlay(alignment: .topTrailing){
                Image("ChangeIcon")
                    .padding(4)
                    .background(Color.white, in: Circle())
                    .padding(5)
            }
    }
}
