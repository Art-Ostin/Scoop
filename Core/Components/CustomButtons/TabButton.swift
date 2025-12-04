//
//  InfoTest.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI

struct TabButton: View {
    let image: Image
    @Binding var isPresented: Bool
    let size: CGFloat
    var isSettings: Bool { size == 20 }
    let padding: CGFloat
    
    init(image: Image, isPresented: Binding<Bool>, size: CGFloat = 17, padding: CGFloat = 6) {
        self.image = image
        _isPresented = isPresented
        self.size = size
        self.padding = padding
    }
    
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
        .frame(maxWidth: .infinity, alignment: isSettings ? .leading : .trailing)
        .padding(.horizontal, isSettings ? 0 : 24)
        .padding(.top, isSettings ? 0 : 60)
    }
}

extension TabButton {
    private var button: some View {
        image
            .font(.body(size))
            .padding(padding)
            .foregroundStyle(.black)
            .onTapGesture {
                isPresented = true
            }
    }
}


extension View {
    @ViewBuilder
    func glassIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(.background))
        } else {
            self
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

