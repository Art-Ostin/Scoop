//
//  RelativeFrameTest.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.


import SwiftUI
struct RelativeFrameTest: View {
    let hPad: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width   // already minus padding
            Image("HaloImage")
                .resizable()
                .scaledToFill()           // keep aspect ratio, fill the square
                .frame(width: side, height: side)
                .clipped()                // crop overflow
        }
        .aspectRatio(1, contentMode: .fit) // makes the reader square
        .padding(.horizontal, hPad)
    }
}

#Preview {
    RelativeFrameTest()
}

/*
 Text("\(screenWidth)")
 
 Image("HaloImage")
     .resizable()
     .scaledToFill() // fill the rect you’re about to define
     .containerRelativeFrame(.horizontal) {length, _ in
         width - 12
     }
     .frame(height: 350) // fixed height
     .clipped() // crop anything that overflows that rect
 */
