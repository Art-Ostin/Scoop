//
//  SignUpTabView2.swift
//  Scoop
//
//  Created by Art Ostin on 26/10/2025.
//

import SwiftUI

struct SignUpTabView: View {
    
    let peek: CGFloat = 72
    var centreOffset: CGFloat { peek / 2}
    @Binding var tabSelection: Int?
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 0) {
                Image("CoolGuys")
                    .resizable().scaledToFit()
                    .frame(height: 200)
                    .containerRelativeFrame(.horizontal) { length, _ in length - peek }
                    .scrollTransition(.interactive, axis: .horizontal) { content, position in
                        content.scaleEffect(position.isIdentity ? 1 : 0.4)
                    }
                    .id(0)
                    .offset(x: tabSelection == 0 ? centreOffset + 2 : 48)
                
                VStack(spacing: 36) {
                    (Text("Skip small talk: ").bold() + Text("No 'likes'. Send an invite with a time & place to meet."))
                    (Text("Social Scoop: ").bold() + Text("Meet one-on-one or meet at an event/bar with each other's friends. (Or a double date!)"))
                }
                .font(.body(.regular))
                .lineSpacing(12)
                .multilineTextAlignment(.center)
                .frame(height: 200)
                .containerRelativeFrame(.horizontal) { length, _ in length - peek}
                .scrollTransition(.interactive, axis: .horizontal) { content, position in
                    content.scaleEffect(position.isIdentity ? 1 : 0.5)
                }
                .id(1)
                .offset(x: tabSelection == 0 ? -16 : -centreOffset)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never)
        .scrollPosition(id: $tabSelection, anchor: .center)
    }
}
