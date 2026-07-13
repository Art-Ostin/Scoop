//
//  OptionPill.swift
//  Scoop
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

/// A selectable capsule pill. The caller owns the selection state and resolves
/// `isSelected`, so one pill serves every option list (String, String?, enum…).
struct OptionPill: View {

    let title: String
    var width: CGFloat = 148 //Geometry: default pill width
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.body(16, .bold))
                .foregroundStyle(isSelected ? Color.white : Color.textPrimary)
                .frame(width: width, height: 44) //Geometry: pill height / min tap target
                .background(isSelected ? Color.accent : Color.fillGray, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OptionPill(title: "Sex", isSelected: true, onTap: {})
}

/// The "custom sex" pill: a stroked, non-selecting capsule that opens the editor.
struct SexOptionPill: View {

    @Binding var gender: String
    @Binding var editText: Bool

    var body: some View {
        Button { editText = true } label: {
            Text(gender)
                .font(.body(16, .bold))
                .padding(.horizontal, Spacing.lg)
                .frame(width: 148, height: 44) //Geometry: matches OptionPill footprint
                .capsuleStroke(lineWidth: 2, color: .accent)
                .overlay(alignment: .topTrailing) {
                    Image("EditButton")
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                        .background(Color.appCanvas)
                        .offset(x: 4, y: -4) //Geometry: nudge edit badge onto the corner
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
