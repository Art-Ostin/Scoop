//
//  SignUpTabView.swift
//  Scoop
//
//  Created by Art Ostin on 26/10/2025.
//

import SwiftUI

/*
struct SignUpTabView: View {
    
    let images = ["CoolGuys", "DancingCats"]
    
    let peek: CGFloat = 60
    
    @State private var currentID: Int? = 0

    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                    Image("CoolGuys")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.7)
                        }
                        .id(0)
                    
                    VStack(spacing: 36) {
                        (Text("Skip small talk: ").bold() + Text("Send someone a time & place to meet. No 'likes'"))
                        (Text("Social Scoop: ").bold() + Text("Meet one-on-one or meet at an event/bar with each other's friends. (Or a double date!)"))
                    }
                    .frame(maxWidth: .infinity)
                    .font(.body(.regular))
                    .lineSpacing(12)
                    .multilineTextAlignment(.center)
                    .containerRelativeFrame(.horizontal)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.7)
                    }
                    .id(1)
                    .ignoresSafeArea()
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $currentID, anchor: .center)
        .contentMargins(.horizontal, peek)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never)
    }
}

#Preview {
    SignUpTabView()
}
*/
