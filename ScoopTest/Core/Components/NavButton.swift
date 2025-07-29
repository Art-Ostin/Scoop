//
//  XButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct NavButton: View {
    
    @Environment(\.dismiss) private var dismiss
    
    enum ViewType { case cross, back, down, right}
    
    let disabled: Bool
    
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
    init(_ type: ViewType = .back, _ size: CGFloat = 17, disabled: Bool = false) {
        self.type = type
        self.size = size
        self.disabled = disabled
    }
    
    var body: some View {
        Button {
            guard !disabled else { return }
            dismiss()
        } label: {
            Image(systemName: imageName)
                .foregroundStyle(.black)
                .font(.body(size, .bold))
        }
    }
}
#Preview(traits: .sizeThatFitsLayout) {
    NavButton(.back)
}
