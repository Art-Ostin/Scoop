//
//  SwiftUIView.swift
//  Scoop
//
//  Created by Art Ostin on 22/11/2025.
//

import SwiftUI

struct ClearRectangle: View {
    let size: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: size, height: size)
    }
}
