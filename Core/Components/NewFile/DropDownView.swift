//
//  DropDownView.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct DropDownView<Row: View, DropDown: View> : View {

    let row: () -> Row
    let dropDown: () -> DropDown
    
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State private var showOptions: Bool = false
    @State private var menuHeight: CGFloat = 0
    @State private var zIndex: Double = 1000.0
    
    private let shadowAllowance: CGFloat = 14
    private let rowHeight: CGFloat = 60

    init(@ViewBuilder row: @escaping () -> Row, @ViewBuilder dropDown: @escaping () -> DropDown) {
        self.row = row
        self.dropDown = dropDown
    }
    
    var body: some View {
        row()
        .frame(height: rowHeight)
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .overlay(alignment: .topLeading) {
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
                    Color.clear.frame(height: rowHeight)
                    
                    dropDown()
                        .padding(24)
                        .readHeight { menuHeight = $0 }
                        .offset(y: showOptions ? 0 : -menuHeight)
                        .opacity(showOptions ? 1 : 0)
                        .mask(alignment: .top) {
                            Rectangle()
                                .padding(shadowAllowance)
                                .frame(height: showOptions ? (menuHeight + shadowAllowance * 2) : 0,
                                       alignment: .top)
                                .offset(y: -shadowAllowance)
                        }
                        .offset(y: -16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .allowsHitTesting(showOptions)
                .animation(.easeInOut(duration: 0.2), value: showOptions)
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

//#Preview {
//    ContentView()
//}
