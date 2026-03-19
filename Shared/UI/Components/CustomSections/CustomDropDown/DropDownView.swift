//
//  DropDownView.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct DropDownView<Row: View, DropDown: View> : View {

    @Binding var showOptions: Bool
    let row: () -> Row
    let dropDown: () -> DropDown
    
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State private var menuHeight: CGFloat = 0
    @State private var zIndex: Double = 1000.0
    
    private let shadowAllowance: CGFloat = 14
    private let rowHeight: CGFloat = 60
    
    let shiftLeft: Bool
    let opensAbove: Bool
    let verticalOffset: CGFloat

    init(shiftLeft: Bool = false, opensAbove: Bool = false, verticalOffset: CGFloat = 24, showOptions: Binding<Bool>, @ViewBuilder row: @escaping () -> Row, @ViewBuilder dropDown: @escaping () -> DropDown) {
        self.shiftLeft = shiftLeft
        self.opensAbove = opensAbove
        self.verticalOffset = verticalOffset
        _showOptions = showOptions
        self.row = row
        self.dropDown = dropDown
    }
    
    var body: some View {
        row()
            .frame(height: rowHeight)
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
                Color.clear.frame(height: rowHeight)
            } else {
                Color.clear.frame(height: rowHeight)
                dropdownMenu
            }
        }
        .allowsHitTesting(showOptions)
    }

    private var dropdownMenu: some View {
        dropDown()
            .padding(24)
            .readHeight { menuHeight = $0 }
            .offset(y: showOptions ? 0 : hiddenOffsetY)
            .mask(alignment: opensAbove ? .bottom : .top) {
                Rectangle()
                    .padding(shadowAllowance)
                    .frame(height: menuHeight + shadowAllowance * 2)
                    .offset(y: opensAbove ? shadowAllowance : -shadowAllowance)
            }
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
            .offset(y: opensAbove ? verticalOffset : -verticalOffset)
            .offset(x: shiftLeft ? -60 : 0)
    }

    private var hiddenOffsetY: CGFloat {
        let hiddenHeight = menuHeight + shadowAllowance * 2
        return opensAbove ? hiddenHeight : -hiddenHeight
    }
}

private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func readHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: ViewHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(ViewHeightKey.self, perform: onChange)
    }
}
