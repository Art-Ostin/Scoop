//
//  DropDownView.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct DropDownView<Row: View, DropDown: View> : View {

    @Binding var showOptions: Bool
    let showDropDownShadow: Bool
    let row: () -> Row
    let dropDown: () -> DropDown
    
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State private var measuredMenuHeight: CGFloat = 0
    @State private var revealedMenuHeight: CGFloat = 0
    @State private var zIndex: Double = 1000.0
    
    private let shadowAllowance: CGFloat = 14
    private let rowHeight: CGFloat = 60
    
    let shiftLeft: Bool
    let opensAbove: Bool
    let verticalOffset: CGFloat

    init(shiftLeft: Bool = false, opensAbove: Bool = false, verticalOffset: CGFloat = 24, showDropDownShadow: Bool = false, showOptions: Binding<Bool>, @ViewBuilder row: @escaping () -> Row, @ViewBuilder dropDown: @escaping () -> DropDown) {
        self.shiftLeft = shiftLeft
        self.opensAbove = opensAbove
        self.verticalOffset = verticalOffset
        self.showDropDownShadow = showDropDownShadow
        _showOptions = showOptions
        self.row = row
        self.dropDown = dropDown
    }
    
    var body: some View {
        row()
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(.rect)
            .overlay(alignment: opensAbove ? .bottom : .top) {
                dropdownRevealOverlay
            }
            .zIndex(zIndex)
            .onChange(of: showOptions) { _, newValue in
                if newValue {
                    index += 1
                    zIndex = index
                }
            }
    }
    
    @ViewBuilder
    private var dropdownRevealOverlay: some View {
        VStack(spacing: 0) {
            if opensAbove {
                dropdownMenu
                rowSpacer
            } else {
                rowSpacer
                dropdownMenu
            }
        }
    }

    private var dropdownMenu: some View {
        dropDown()
            .padding(24)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: syncMenuHeight)
            .offset(y: showOptions ? 0 : hiddenOffsetY)
            .mask(alignment: opensAbove ? .bottom : .top) {
                Rectangle()
                    .padding(shadowAllowance)
                    .frame(height: revealedMenuHeight + shadowAllowance * 2)
                    .offset(y: opensAbove ? shadowAllowance : -shadowAllowance)
            }
            .customShadow(.floating, strength: showDropDownShadow ? 0.7 : 0)
            .offset(y: opensAbove ? verticalOffset : -verticalOffset)
            .offset(x: shiftLeft ? -60 : 0)
            .allowsHitTesting(showOptions)
    }

    private var rowSpacer: some View {
        Color.clear
            .frame(height: rowHeight)
            .allowsHitTesting(false)
    }

    private var hiddenOffsetY: CGFloat {
        let hiddenHeight = revealedMenuHeight + shadowAllowance * 2
        return opensAbove ? hiddenHeight : -hiddenHeight
    }

    private func syncMenuHeight(_ newHeight: CGFloat) {
        guard abs(measuredMenuHeight - newHeight) > 0.5 else { return }

        measuredMenuHeight = newHeight

        if showOptions {
            withAnimation(.smooth(duration: 0.2, extraBounce: 0)) {
                revealedMenuHeight = newHeight
            }
        } else {
            revealedMenuHeight = newHeight
        }
    }
}

