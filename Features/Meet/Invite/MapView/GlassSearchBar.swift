//
//  \.swift
//  Scoop
//
//  Created by Art Ostin on 03/02/2026.
//

import SwiftUI

import SwiftUI

struct GlassSearchBar2: View {

    @Binding var text: String
    @Binding var showSheet: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black)
            
            
            
            Text("Search Maps")
                .font(.system(size: 17))
                .foregroundStyle(Color.black.opacity(0.76))
            
//            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 35)
        .background(Capsule().fill(.ultraThinMaterial))
        .frame(height: 65)
        .padding(.horizontal, 16)
        .contentShape(Capsule())
        .glassIfAvailable(Capsule(), isClear: false)
        .clipShape(Capsule())
        .padding(.horizontal, 36)
    }
}

/*
 //        .onTapGesture {
 //            showSheet = true
 //        }

 */


/*
 //            Text("Search Maps")
 //                TextField("Search Maps", text: $text)
 //                    .font(.system(size: 17))
 //                    .foregroundStyle(Color.black)
 //                    .focused($isFocused)
 //                    .textInputAutocapitalization(.never)
 //                    .autocorrectionDisabled()

 */
