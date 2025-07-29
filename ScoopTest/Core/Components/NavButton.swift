//
//  XButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct NavButton: View {
    
    
    @Environment(\.dismiss) private var dismiss
    enum ViewType { case cross, back, down}
    
    let type: ViewType

    private var imageName: String {
        switch type {
        case .cross: return "xmark"
        case .back:  return "chevron.left"
        case .down:  return "chevron.down"
        }
    }
    init(_ type: ViewType = .back) {
        self.type = type
    }
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: imageName)
                .foregroundStyle(.black)
                .font(.body(17, .bold))
        }
    }
}
#Preview(traits: .sizeThatFitsLayout) {
    NavButton(.back)
}
