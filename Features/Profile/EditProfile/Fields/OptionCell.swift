//
//  OptionCell.swift
//  Scoop
//
//  Created by Art Ostin on 12/08/2026.
//

import SwiftUI

enum OptionCellStyle { case filled, outlined }   // how selection reads

struct OptionCell: View {

    //Injected
    let text: String
    var maxCount: Int = .max            // .max: a cell that can never refuse (the selected-chip rows)
    @Binding var selection: [String]
    var style: OptionCellStyle = .filled
    var isLanguages: Bool = false

    //Local view state
    @State private var shake = false        // the event: toggled to play one shake
    @State private var hasHitMax = false    // the duration: the label is showing the limit

    var isSelected: Bool { selection.contains(text) }
    var optionFilled: Bool { isSelected && style == .filled }

    var fontColor: Color { hasHitMax ? .textAccent : optionFilled ? .white : .textPrimary }
    var strokeColor: Color { isSelected || hasHitMax ? .accent : .border }
    var backgroundColor: Color { optionFilled ? .accent : .appCanvas }

    var body: some View {
        Button { onTap() } label: { chip }
            .shrinkButton()
            .showShakeAnimation(bool: shake)
            .sensoryFeedback(.warning, trigger: shake)
            .task(id: shake) { await clearHitMax() }
    }
}

// MARK: - The chip
extension OptionCell {

    private var chip: some View {
        label
            //The size of the Button
            .padding(.horizontal, isLanguages ? Spacing.sm : Spacing.xs)
            .padding(.vertical, Spacing.sm)

            .font(.body(isLanguages ? 15 : 14))
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            //The Color of the button
            .background(backgroundColor, in: .rect(cornerRadius: CornerRadius.sm))
            .stroke(CornerRadius.sm, color: strokeColor)

            .overlay(alignment: .topTrailing) {xmarkIcon}

            //Stable ancestor of the label swap — the press animates outside this, in the button style
            .animation(.transition, value: hasHitMax)
    }

    private var label: some View {
        Text(text).hidden().overlay {
            Text(hasHitMax ? "Max \(maxCount)" : text)
                .foregroundStyle(fontColor)
                .id(hasHitMax)
                .transition(.blurReplace)
        }
    }

    private var xmarkIcon: some View {
        CircleIcon("xmark")
            .opacity(isSelected ? 1 : 0)
            .offset(x: 6,  y: -6) //Geometry: hangs the badge on the chip's corner
    }
}

// MARK: - Selection
extension OptionCell {

    private func onTap() {
        if isSelected {
            withAnimation(.toggle) { selection.removeAll { $0 == text } }
        } else if selection.count >= maxCount {
            hasHitMax = true
            shake.toggle()
        } else {
            withAnimation(.toggle) { selection.append(text) }
        }
    }

    private func clearHitMax() async {
        guard hasHitMax else { return }
        do { try await Task.sleep(for: .seconds(1)) } catch { return } //a newer refusal owns the label
        hasHitMax = false
    }
}
