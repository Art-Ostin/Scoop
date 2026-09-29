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
    var isCapsule: Bool = false
    @Binding var selection: [String]
    var style: OptionCellStyle = .filled
    var isLanguages: Bool = false
    var isCircle: Bool = false

    //Local view state
    @State private var shake = false        // the event: toggled to play one shake
    @State private var hasHitMax = false    // the duration: the label is showing the limit
    @State private var chipHeight: CGFloat = 0  // a capsule's corner radius is half of it — see `badgeOffset`

    var isSelected: Bool { selection.contains(text) }
    var neverShrinks: Bool { isCapsule || isCircle }
    var optionFilled: Bool { isSelected && style == .filled }
    var fillsBlack: Bool { isCapsule || isCircle }

    var fontColor: Color { optionFilled ? .white : .textPrimary }

    var strokeColor: Color {
        if isSelected && fillsBlack { return .blackFill }
        return isSelected || hasHitMax ? .accent : .border
    }
    
    var backgroundColor: Color {
        optionFilled ? (fillsBlack ? .blackFill : .accent) : .appCanvas
    }

    var body: some View {
        Button { onTap() } label: {
            if isCircle {
                circleLabel
                
            } else {
                chip
            }
        }
            .shrinkButton()
            .showShakeAnimation(bool: shake)
            .sensoryFeedback(.warning, trigger: shake)
            .task(id: shake) { await clearHitMax() }
    }
}

// MARK: - The chip
extension OptionCell {

    private var chip: some View {
        let cornerRadius: CGFloat = isCapsule ? 100 : CornerRadius.sm
        let horizontalPadding: CGFloat = isLanguages || isCapsule ? Spacing.sm :  Spacing.xs 
        
        return label
            //A capsule never abbreviates: the label claims its ideal width, so an over-full row
            //overruns the margin in plain sight instead of quietly truncating a word away.
            .fixedSize(horizontal: isCapsule, vertical: false)

            //The size of the Button
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, Spacing.sm)

            .font(.body(isLanguages ? 15 : 14))
            .lineLimit(1)
            .minimumScaleFactor(isCapsule ? 1 : 0.5)

            .background(backgroundColor, in: .rect(cornerRadius: cornerRadius))
            .stroke(cornerRadius, color: strokeColor)
            .animation(nil, value: isSelected)

            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { chipHeight = $0 }
            .overlay(alignment: .topTrailing) {xmarkIcon}

            //Stable ancestor of the label swap — the press animates outside this, in the button style
            .animation(.transition, value: hasHitMax)
    }
    
    /// A fixed dot. The row spaces the dots with `Spacer`s rather than a hardcoded gap, so the
    /// first and last sit flush on the page margin and the leftover width is split between them.
    private var circleLabel: some View {
        label
            .font(.body(hasHitMax ? 12 : 14))

//            .font(.body(14))                                //the capsules' size: one type size per screen
            .lineLimit(hasHitMax ? 2 : 1)   //the refusal stacks "Max" over the number; the option is one line
            .fixedSize(horizontal: true, vertical: false)    //inside the frame, where it can still refuse a squeeze
            .frame(width: 42, height: 42) //Geometry: the dot; the cell around it flexes with the device

            .background(backgroundColor, in: Circle())
            .circleStroke(lineWidth: 1, color: strokeColor)
            .animation(nil, value: isSelected)

            .contentShape(Rectangle())

            .animation(.transition, value: hasHitMax)
    }
    
    private var label: some View {
        let warningText = isCircle ? "Max\n\(maxCount)" : "Max \(maxCount)"
        return Text(text).hidden().overlay {
            if hasHitMax {
                Text(warningText)
                    //vertical: the dot's two-liner takes its ideal height, overflowing the
                    //hidden one-line sizer — the 42pt frame has the room and nothing clips.
                    .fixedSize(horizontal: neverShrinks, vertical: isCircle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textAccent)
                    .transition(.blurReplace)
            } else {
                Text(text)
                    .fixedSize(horizontal: neverShrinks, vertical: false)
                    .foregroundStyle(fontColor)
                    .transition(.blurReplace)
            }
        }
    }

    private static let badgeHang: CGFloat = 6
    private static let arcPull: CGFloat = 1 - 1 / CGFloat(2).squareRoot()

    private var badgeOffset: CGFloat {
        guard isCapsule, chipHeight > 0 else { return Self.badgeHang }
        return Self.badgeHang - (chipHeight / 2 - CornerRadius.sm) * Self.arcPull
    }

    private var xmarkIcon: some View {
        CircleIcon("xmark")
            .opacity(isSelected ? 1 : 0)
            .offset(x: badgeOffset, y: -badgeOffset)
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
