//
//  XButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct XButton: View {
    
    @Environment(AppState.self) private var appState
        
    
    let isSave: Bool
    
    init(isSave: Bool = false) {
        self.isSave = isSave
    }
    
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0, dampingFraction: 0.8, blendDuration: 0)){
                if isSave {
                    appState.stage = .limitedAccess
                } else {
                    appState.stage = .signUp
                }
            }
        }
        label: {
            if isSave {
                Text("Save")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundStyle(Color.grayText)
                    .font(.body(14))
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            } else {
                HStack {
                    Image(systemName: "xmark")
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .font(.system(size: 17))
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    XButton()
        .environment(AppState())
}
