//
//  HistoryScrollSection.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/08/2026.
//


import SwiftUI


struct SelectionSection: View {
    private static let selectionSpace = "historySelection"
    @Binding var selectedPage: Int?
    @Bindable var ui: HistoryUIState

    var body: some View {
        HStack {
            Image(.smallDeclineBlack)
                .scaleEffect(0.9)
                .shrinkPress { selectedPage = 0 }
                .getRect($ui.declineIconFrame, coordSpace: Self.selectionSpace)
            
            Spacer()
            Image(.inviteBlack)
                .shrinkPress { selectedPage = 1 }
                .getRect($ui.inviteIconFrame, coordSpace: Self.selectionSpace)
        }
        .padding(.horizontal, 90)
        .coordinateSpace(name: Self.selectionSpace)
        .overlay(alignment: .bottomLeading) {
            SelectionUnderline(ui: ui)
                .offset(y: Spacing.sm) //Rests just below the icon row
                .allowsHitTesting(false) //Decorative — its overhang must not steal the pager's pan
        }
    }
}

struct SelectionUnderline: View {
    //Injected
    let ui: HistoryUIState

    private static let width: CGFloat = 38

    var body: some View {
        let progress = min(max(ui.pagerProgress, 0), 1) //Rubber-banding runs past both ends
        let from = ui.declineIconFrame.midX
        let to = ui.inviteIconFrame.midX

        RoundedRectangle(cornerRadius: 2)
            .frame(width: Self.width, height: 2.5)
            .foregroundStyle(Color.accent)
            .offset(x: from + (to - from) * progress - Self.width / 2) //Centered on the anchor
            .opacity(ui.inviteIconFrame == .zero ? 0 : 1) //Hidden until the anchors are measured
    }
}
