//
//  \.swift
//  Scoop
//
//  Created by Art Ostin on 03/02/2026.
//

import SwiftUI

import SwiftUI

struct GlassSearchBar: View {

    @Binding var text: String
    @Binding var showSheet: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black)

                TextField("Search Maps", text: $text)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.black)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 35)
        .background(Capsule().fill(.ultraThinMaterial))
        .frame(height: 65)
        .padding(.horizontal, 16)
        .contentShape(Capsule())
        .onTapGesture {
//            isFocused = true
            showSheet = true
        } // taps anywhere focuses the field
        .glassIfAvailable(Capsule(), isClear: false)
        .clipShape(Capsule())
        .padding(.horizontal, 36)
    }
}

