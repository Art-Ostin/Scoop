//
//  InfoTest.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI

struct TabButton: View {
    let page: Page
    @Binding var isPresented: Bool
    
    var body: some View {
        if page != .EditProfile || page != .Matches {
            button
                .glassIfAvailable()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

extension TabButton {
    private var button: some View {
        page.image
            .font(.body(page == .Matches ? 20 : 17))
            .padding(6)
            .foregroundStyle(.black)
            .onTapGesture {
                isPresented = true
            }
    }
}


extension View {
    @ViewBuilder
    func glassIfAvailable(_ shape: any Shape = .capsule) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.clear, in: shape)
        } else {
            self
                .background( Circle().fill(Color.background) )
                .overlay( Circle().strokeBorder(Color.grayBackground, lineWidth: 0.4) )
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }
}

extension View {
    @ViewBuilder
    func glassRectangle() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: .rect(cornerRadius: 36))
        } else {
            self
        }
    }
}

extension ToolbarContent {
    @ToolbarContentBuilder
    func hideSharedBackgroundIfAvailable() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}

struct DefaultAppButton: View {
    let image: Image
    let size: CGFloat
    @Binding var isPresented: Bool
    
    var body: some View {
            Group {
                if #available(iOS 26.0, *) {
                    button
                        .glassEffect()
                } else {
                    button
                        .background( Circle().fill(Color.background) )
                        .overlay( Circle().strokeBorder(Color.grayBackground, lineWidth: 0.4) )
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 24)
        }
}

extension DefaultAppButton {
    private var button: some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .padding(6)
            .contentShape(Circle())
            .onTapGesture { isPresented = true }
    }
}


struct CloseToolBar: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    let imageString: String
    let isLeading: Bool
    init(imageString: String = "xmark", isLeading: Bool = true) {
        self.imageString = imageString
        self.isLeading = isLeading
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: isLeading ? .topBarLeading : .topBarTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: imageString).font(.body.weight(.semibold))
            }
        }
    }
}

