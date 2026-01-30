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

    init(showOptions: Binding<Bool>, @ViewBuilder row: @escaping () -> Row, @ViewBuilder dropDown: @escaping () -> DropDown) {
        _showOptions = showOptions
        self.row = row
        self.dropDown = dropDown
    }
    
    var body: some View {
        row()
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(.rect)
            .overlay(alignment: .top) {
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
                .offset(y: showOptions ? 0 : -(menuHeight + shadowAllowance * 2))
                .mask(alignment: .top) {
                    Rectangle()
                        .padding(shadowAllowance)
                        .frame(height: menuHeight + shadowAllowance * 2,
                               alignment: .top)
                        .offset(y: -shadowAllowance)
                }
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
                .offset(y: -24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(showOptions)
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

/* Fixed some unwanted animation
 /*
  .opacity(showOptions ? 1 : 0)
  .transition(.move(edge: .top).combined(with: .opacity))
  .animation(.snappy(duration: 0.22, extraBounce: 0.02), value: showOptions)
  */

 */
