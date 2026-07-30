//
//  ConfirmTypeButton.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/07/2026.
//

import SwiftUI

struct TypeButton: View{
    
    let type: Event.EventType
    var timeOpen: Bool
    let isCard: Bool
    
    let showInfo: () -> ()
    
    var textTint: Color {
        isCard ? .white : .textPrimary.mix(with: .accent, by: 0.2)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Image(type.emoji).font(.body(15))
            
            HStack(spacing: 2) {
                titleText
                if !isCard {infoCircle}
            }
        }
        .typeButtonModifier(isCard: isCard) { showInfo()}
        .opacityPop(visible: !timeOpen)
    }
    
    var titleText: some View {
        Text(type.longTitle)
            .font(.body(15, .bold))
            .foregroundStyle(textTint) //Subtle Tint of accent
            .kerning(isCard ? 0 : -0.1)
    }
    
    var infoCircle: some View {
        Image(systemName:"info.circle")
            .font(.body(9, .regular))
            .foregroundStyle(Color.textPlaceholder.mix(with: Color.accent, by: 0.1)) //Subtle Tint of accent
            .offset(y: -3)
            .offset(x: 1)
    }
}

extension View {
    @ViewBuilder
    func typeButtonModifier(isCard: Bool, showInfo: @escaping () -> ()) -> some View {
        self
            .padding(.horizontal, isCard ? 10 : 12)
            .padding(.vertical, isCard ? 6 : 8)
            .background(isCard ? Color.clear : Color.accent.opacity(0.05).mix(with: Color.fillGray, by: 0.5), in: Capsule())
            .stroke(12, lineWidth: 1, color: isCard ? .white.opacity(0.6) : Color.clear)
            .padding(.horizontal, isCard ? 0 : 24)
            .shrinkPress { showInfo() }
            .offset(y: isCard ? 1.5 : 2)
            .scaleEffect(isCard ? 0.8 : 0.85, anchor: isCard ? .bottomTrailing : .trailing)
    }
}
