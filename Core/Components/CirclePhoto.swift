//
//  CirclePhoto.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import SwiftUI

struct CirclePhoto: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 35, height: 35)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
    }
}


struct ChangeIcon: View {
    var body: some View {
        Image("ChangeIcon")
        .padding(12)
        .frame(width: 24, height: 24)
        .background (
            Circle()
                .fill(Color.white)
        )
        .padding(6)
    }
}

struct RemoveIcon: View {
    var body: some View {
        Image(systemName: "xmark")
            .font(.body(12, .bold))
            .padding(12)
            .frame(width: 24, height: 24)
            .background (Circle().fill(Color.background))
            .padding(6)
            .scaleEffect(0.7)
    }
}


//#Preview {
//    CirclePhoto()
//}
