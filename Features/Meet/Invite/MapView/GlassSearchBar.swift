//
//  \.swift
//  Scoop
//
//  Created by Art Ostin on 03/02/2026.
//

import SwiftUI

struct GlassSearchBar: View {
    var body: some View {
            innerBar
    }

    private var innerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.black)

            Text("Search Maps")
                .font(.system(size: 17))
                .foregroundStyle(Color.grayText.opacity(0.85))
            
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

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.85, green: 0.95, blue: 0.90), Color(red: 0.80, green: 0.88, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassSearchBar()
            .padding(.horizontal, 24)
    }
}
