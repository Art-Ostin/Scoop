//
//  XButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct NavButton: View {
    
    @Environment(\.dismiss) private var dismiss
    let action: (() -> Void)?
    enum ViewType { case cross, back, down, right}
    
    
    let type: ViewType
    let size: CGFloat
    
    private var imageName: String {
        switch type {
        case .cross: return "xmark"
        case .back:  return "chevron.left"
        case .down:  return "chevron.down"
        case .right: return  "chevron.right"
        }
    }
    init(_ type: ViewType = .back, _ size: CGFloat = 17, action: (() -> Void)? = nil) {
        self.type = type
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: imageName)
                .foregroundStyle(.black)
                .font(.body(size, .bold))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
    }
}
#Preview(traits: .sizeThatFitsLayout) {
    NavButton(.back)
}

struct profileDismissButton : View {
    
    @Binding var selectedProfile: ProfileModel?
    let color: Color
    
    var body: some View {
        Image(systemName: "chevron.down")
            .font(.body(18, .bold))
            .foregroundStyle(color)
            .contentShape(Rectangle())
            .onTapGesture {selectedProfile = nil}
    }
}
