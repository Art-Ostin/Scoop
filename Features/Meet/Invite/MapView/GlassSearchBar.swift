//
//  \.swift
//  Scoop
//
//  Created by Art Ostin on 03/02/2026.
//

import SwiftUI

struct GlassSearchBar: View {

    @Binding var showSheet: Bool
    
    let text: String
    
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black)
            
            
            Text( text.isEmpty ? "Search Maps" : text)
                .font(.system(size: 17))
                .foregroundStyle(Color.black.opacity(0.76))
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 45)
        .background(Capsule().fill(.ultraThinMaterial))
        .contentShape(Capsule())
        .padding(.horizontal, 16)
    }
}

/*
 .frame(height: 65)
 .padding(.horizontal, 16)

 */

//        .glassIfAvailable(Capsule(), isClear: false)
//
//    .padding(.horizontal, 36)
//    .onTapGesture {
//        showSheet = true
//    }

