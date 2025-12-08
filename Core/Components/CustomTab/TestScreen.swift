//
//  TestScreen.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI

struct TestScreen: View {
    @Binding var showTestScreen: Bool
    var body: some View {
        VStack {
            Text("Hello, World!")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.red)
        .onTapGesture {
            showTestScreen.toggle()
        }
    }
}
