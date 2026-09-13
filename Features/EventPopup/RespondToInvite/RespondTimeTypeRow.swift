//
//  RespondTimeTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 13/09/2026.
//

import SwiftUI

private let iconWidth: CGFloat = 20 //Every icon sits in the same column
private let iconGap: CGFloat = 20 //Icon column ↔ text
private let textColumn = iconWidth + iconGap //Where the paged text, its mask and the dots start
private let rowHeight: CGFloat = 33

//The type row as a pager as wide as the whole row: a swipe anywhere pages the text, the emoji stays put
struct RespondTimeTypeRow: View {

    //Injected
    let eventType: Event.EventType
    let message: String //Not optional as only screen when there is a message
    let showInfo: () -> ()

    //Local view state
    @State private var scrollProgress: Double = 0

    var body: some View {
        HorizontalScrollView(progress: $scrollProgress, holdsPageOnResize: true) { //The respond card widens when its note is focused
            eventTitleAndInfo
                .frame(minHeight: rowHeight) //Inside the pager, so a swipe anywhere in the row's box pages it
                .padding(.leading, textColumn)
                .containerRelativeFrame(.horizontal, alignment: .leading)
            messageView
                .padding(.leading, textColumn) //Inside the page's own width, so the pager keeps its size
                .containerRelativeFrame(.horizontal, alignment: .leading)
        }
        .mask { edgeFadeMask } //A mask leaves the touch area whole, so a swipe that starts on the emoji still pages
        .animation(.quick, value: isScrolling)
        .background(alignment: .leading) { emoji } //Under the pager: it never scrolls, and a swipe that starts on it still reaches the pager
        .overlay(alignment: .bottomLeading) {
            pageIndicator
        }
    }
}

extension RespondTimeTypeRow {

    private var emoji: some View {
        Text(eventType.emoji)
            .font(.body(16, .bold))
            .frame(width: iconWidth)
    }

    private var eventTitleAndInfo: some View {
        Button {
            showInfo()
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Text(eventType.longTitle)
                    .font(.body(17, .bold))
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.textTertiary)
                    .font(.body(11, .medium))
                    .offset(x: -8, y: -2) //Geometry: nudged in toward the title
            }
        }
        .shrinkButton() //Not growButton: the pager clips a grow at its edge
    }

    //Hangs just under the pager, which is as tall as its tallest page, so it never lands on either page's text
    private var pageIndicator: some View {
        InvitePageIndicator(count: 2, progress: scrollProgress)
            .padding(.leading, textColumn) //Under the text, not the emoji
            .alignmentGuide(.bottom) { $0[.top] - Spacing.xxs }
    }

    private var messageView: some View {
        Text(message)
            .font(.body(14, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3, minimum: 0.7) //then the tail truncates
            .fixedSize(horizontal: false, vertical: true)
    }

    private var isScrolling: Bool { scrollProgress > 0.01 && scrollProgress < 0.99 }

    //InviteTypeRow's scroll fade, starting at the text column: the pages end there, and both edges fade only while they move
    private var edgeFadeMask: some View {
        let fade: CGFloat = isScrolling ? Spacing.md : 0
        return HStack(spacing: 0) {
            Color.clear.frame(width: textColumn)
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing).frame(width: fade)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: fade)
        }
    }
}
