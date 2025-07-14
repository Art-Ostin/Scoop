//
//  XButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct XButton: View {
    
    
    var onTap: (() -> Void)
    
    var body: some View {
        
        
        Button {
            onTap()
        } label: {
            Image(systemName: "xmark")
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .font(.system(size: 17))
        }
        
//        Button {
//            withAnimation(.spring(response: 0, dampingFraction: 0.8, blendDuration: 0)){
//                if isSave {
//                    appState.stage = .limitedAccess
//                } else {
//                    appState.stage = .signUp
//                }
////            }
//        }
//        label: {
//            if isSave {
//                Text("Save")
//                    .frame(maxWidth: .infinity, alignment: .trailing)
//                    .foregroundStyle(Color.grayText)
//                    .font(.body(14))
//                    .padding(.top, 12)
//                    .padding(.trailing, 12)
//            } else {
//                HStack {
//                    Image(systemName: "xmark")
//                        .fontWeight(.bold)
//                        .foregroundStyle(.black)
//                        .font(.system(size: 17))
//                }
//            }
//        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    XButton(onTap: {})
        .environment(AppState())
}
