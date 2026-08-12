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

    var fontColor: Color { optionFilled ? .white : .textPrimary }
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

            //The Color of the button — the selection colours land whole. Inside the tap's
            //`.toggle` (which the rows above need for their insert) they would ramp in from the
            //old colour, and a fill that catches up with the tap reads as lag. Sits under the
            //badge overlay, so the xmark still fades.
            .background(backgroundColor, in: .rect(cornerRadius: CornerRadius.sm))
            .stroke(CornerRadius.sm, color: strokeColor)
            .animation(nil, value: isSelected)

            .overlay(alignment: .topTrailing) {xmarkIcon}

            //Stable ancestor of the label swap — the press animates outside this, in the button style
            .animation(.transition, value: hasHitMax)
    }

    /// Two branches, not one `Text` swapping its string on an `.id` — a leaf whose
    /// value changes is diffed as an update, and the transition never fires.
    private var label: some View {
        Text(text).hidden().overlay {
            if hasHitMax {
                Text("Max \(maxCount)")
                    .foregroundStyle(Color.textAccent)
                    .transition(.blurReplace)
            } else {
                Text(text)
                    .foregroundStyle(fontColor)
                    .transition(.blurReplace)
            }
        }
    }

    private var xmarkIcon: some View {
        CircleIcon("xmark")
            .opacity(isSelected ? 1 : 0)
            .offset(x: 6,  y: -6) //Geometry: hangs the badge on the chip's corner
    }
}

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
