//
//  HistorySelectionSection.swift
//  Scoop
//
//  Created by Art Ostin on 22/08/2026.
//


import SwiftUI


struct SelectionSection: View {
    private static let selectionSpace = "historySelection"

    //Geometry: how far the underline hangs below the icon row. The section reserves the same
    //amount beneath itself, so its bottom edge — and with it the scroll view's top — is the
    //underline's bottom rather than the icons'.
    private static let underlineDrop = Spacing.sm - Spacing.hairline

    @Binding var selectedPage: Int?
    @Bindable var ui: HistoryUIState

    //Listed in page order, left to right — mirror the pager here and nothing else needs rewiring
    var body: some View {
        HStack {
            icon(.inviteBlack, page: 0)

            Spacer()

            icon(.smallDeclineBlack, page: 1, scale: 0.9)
        }
        .padding(.horizontal, 90)
        .coordinateSpace(name: Self.selectionSpace)
        .overlay(alignment: .bottomLeading) {
            SelectionUnderline(ui: ui)
                .offset(y: Self.underlineDrop) //Rests just below the icon row
                .allowsHitTesting(false) //Decorative — its overhang must not steal the pager's pan
        }
        .padding(.bottom, Self.underlineDrop) //After the overlay, which still anchors to the icons' bottom
    }
}

extension SelectionSection {

    //One `page` drives both the tap target and the underline's anchor, so the two can't
    //drift apart from each other or from the pager.
    private func icon(_ resource: ImageResource, page: Int, scale: CGFloat = 1) -> some View {
        Image(resource)
            .scaleEffect(scale)
            .shrinkPress { selectedPage = page }
            .getRect($ui.pageIconFrames[page], coordSpace: Self.selectionSpace)
    }
}

struct SelectionUnderline: View {
    //Injected
    let ui: HistoryUIState

    private static let width: CGFloat = 38

    var body: some View {
        let progress = min(max(ui.pagerProgress, 0), 1) //Rubber-banding runs past both ends
        let from = ui.pageIconFrames[0].midX
        let to = ui.pageIconFrames[1].midX

        RoundedRectangle(cornerRadius: 2)
            .frame(width: Self.width, height: 2.5)
            .foregroundStyle(Color.accent)
            .offset(x: from + (to - from) * progress - Self.width / 2) //Centered on the anchor
            .opacity(ui.pageIconFrames.contains(.zero) ? 0 : 1) //Hidden until every anchor is measured
    }
}
