//
//  ScrollTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/06/2025.
//

import SwiftUI

struct ScrollTest: View {
    @State private var items: [String] = [
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen",
        "nineteen", "twenty", "twenty one", "twenty two", "twenty three", "twenty four"
    ]

    var body: some View {
        VStack {
            // ➀ Wrap header + ScrollView in ScrollViewReader
            ScrollViewReader { proxy in
                // Header of buttons
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Row 1: 1–13
                        ForEach(1...13, id: \.self) { num in
                            Button("\(num)") {
                                proxy.scrollTo(num - 1, anchor: .top)
                            }
                            .font(.headline)
                        }
                    }

                    HStack(spacing: 12) {
                        // Row 2: 14–24
                        ForEach(14...24, id: \.self) { num in
                            Button("\(num)") {
                                proxy.scrollTo(num - 1, anchor: .top)
                            }
                            .font(.headline)
                        }
                    }
                }
                .padding(.vertical, 8)

                
                
                // ➁ The ScrollView you can jump around in
                ScrollView {
                    VStack(spacing: 36) {
                        ForEach(Array(items.enumerated()), id: \.element) { index, item in
                            Text("\(index + 1): \(item)")
                                .font(.custom("NewYorkLarge-Bold", size: 32))
                                .id(index)   // ← each row gets its numeric ID
                        }
                    }
                    .padding(.top, 16) // optional: add a bit of top padding
                }
                .frame(height: 300)
            }
        }
    }
}


#Preview {
    ScrollTest()
}
