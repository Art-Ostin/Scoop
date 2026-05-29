//
//  CustomNavigation.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/05/2026.
//

import SwiftUI

struct NavigationTest: View {

    var body: some View  {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(Images.allCases) { image in
                        Image(image.rawValue)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .navigationTitle("Meeting")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    NavigationTest()
}

enum Images: String, CaseIterable, Identifiable {

    case img1 = "Demo1"
    case img2 = "Demo2"
    case img3 = "Demo3"
    case img4 = "Demo4"
    case img5 = "Demo5"
    case img6 = "Demo6"
    case img7 = "Demo7"
    case img8 = "Demo8"

    var id: Self { self }

}
