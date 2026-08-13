//
//  VicesRow.swift
//  Scoop Test
//
//  Created by Art Ostin on 13/08/2026.
//

import SwiftUI

enum ViceStatus { case yes, no, occasionally }

struct VicesRow: View {
    let drinking: ViceStatus
    let smoking: ViceStatus
    let marijuana: ViceStatus
    let drugs: ViceStatus

    private var items: [(icon: String, status: ViceStatus)] {
        [("ScoopDrinkIcon", drinking), ("ScoopCigaretteIcon", smoking),
         ("ScoopWeedIcon", marijuana), ("ScoopDrugIcon", drugs)]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.icon) { item in
                ViceItem(icon: item.icon, status: item.status)
                    .frame(maxWidth: .infinity) //Equal columns, so each glyph stays centred on its own icon
            }
        }
    }
}

struct ViceItem: View {
    let icon: String
    let status: ViceStatus
    
    var iconSize: CGFloat = 20
    var glyphHeight: CGFloat = 7 //The tallest glyph's natural height, so the two rows stay pinned

    var body: some View {
        VStack(spacing: Spacing.xs) {
            //Fixed boxes for both rows, so the
            //four items align regardless of glyph or icon proportions
            Rectangle()
                .fill(Color.clear)
                .frame(width: iconSize, height: glyphHeight)
                .overlay {glyph}

            Rectangle()
                .fill(Color.clear)
                .frame(width: iconSize, height: iconSize)
                .overlay {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                    
                }
        }
        .foregroundStyle(Color.textPrimary)
    }

    @ViewBuilder
    private var glyph: some View {
        switch status {
        case .yes: Image("TickSVG").scaleEffect(1.4)
        case .occasionally: Image("Tilde").scaleEffect(1.2)
        case .no: Image(systemName: "xmark").font(.icon(12, .semibold))
        }
    }
}



#Preview {
    VicesRow(drinking: .yes, smoking: .yes, marijuana: .occasionally, drugs: .no)
        .padding(.horizontal, Spacing.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appCanvas)
}
