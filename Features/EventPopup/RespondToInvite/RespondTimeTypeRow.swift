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
private let rowHeightIncrease: CGFloat = 19.5 //Geometry: InviteTypeRow's — the pages draw this much taller than the row, so 3 message lines fit
private let messageSize: CGFloat = 14

//The type row as a pager as wide as the whole row: a swipe anywhere pages the text, the emoji stays put
struct RespondTimeTypeRow: View {

    //Injected
    let eventType: Event.EventType
    let message: String //Not optional as only screen when there is a message
    let showInfo: () -> ()

    //Local view state
    @State private var scrollProgress: Double = 0
    @State private var messageWidth: CGFloat = 0 //The width the message wraps in, so its lines can be counted

    var body: some View {
        HorizontalScrollView(progress: $scrollProgress, holdsPageOnResize: true) { //The respond card widens when its note is focused
            eventTitleAndInfo
                .frame(height: rowHeight + rowHeightIncrease) //Inside the pager, so a swipe anywhere in the row's box pages it
                .offset(y: contentLift) //Cancels the box lift: only the message page should rise
                .padding(.leading, textColumn)
                .containerRelativeFrame(.horizontal, alignment: .leading)
//            messageView
//                .padding(.leading, textColumn) //Inside the page's own width, so the pager keeps its size
//                .containerRelativeFrame(.horizontal, alignment: .leading)
        }
        .mask { edgeFadeMask } //A mask leaves the touch area whole, so a swipe that starts on the emoji still pages
        .animation(.quick, value: isScrolling)
//        .overlay(alignment: .bottomLeading) { pageIndicator } //On the drawn box: its offsets step from that box's foot
        .padding(.top, -(rowHeightIncrease / 2 + contentLift)) //Back to rowHeight: the pages spill into the gaps above and below, never grow the card
        .padding(.bottom, -(rowHeightIncrease / 2 - contentLift))
        .background(alignment: .leading) { emoji } //Under the pager: it never scrolls, and a swipe that starts on it still reaches the pager
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

    //InviteTypeRow's dots: they step with the message's line count, so they never land on its text
    private var pageIndicator: some View {
        InvitePageIndicator(count: 2, progress: scrollProgress)
            .offset(y: indicatorOffset)
            .animation(.move, value: indicatorOffset) //After the offset, so the step itself animates
            .padding(.leading, textColumn) //Under the text, not the emoji
    }

    private var messageView: some View {
        Text(message)
            .font(.body(messageSize, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3, minimum: 0.7) //then the tail truncates
            .frame(maxWidth: .infinity, alignment: .leading)
            .getWidth($messageWidth)
            .fixedSize(horizontal: false, vertical: true)
            .frame(height: rowHeight + rowHeightIncrease)
            .offset(y: messageLineCount == 2 ? -5 : 0) //Geometry: 3 lines lift via contentLift instead: no slack to translate into
    }

    private var messageLineCount: Int {
        let metrics = message.lineMetrics(
            font: .body(messageSize, .regularItalic), //lineMetrics' contract: must match the drawn Text exactly
            lineSpacing: 0,                           //The drawn Text sets none
            width: messageWidth
        )
        return min(3, metrics.count) //It measures at full size; the drawn text shrinks and never passes 3
    }

    //Three lines fill the page to within 1.05pt, so the lift has to move the BOX, not the content
    private var contentLift: CGFloat { messageLineCount == 3 ? 5 : 0 } //Geometry: InviteTypeRow's lift

    //Geometry: InviteTypeRow's steps, measured from the drawn box's foot
    private var indicatorOffset: CGFloat {
        guard scrollProgress > 0.5 else { return -6 }   //Title page: no nudge
        return switch messageLineCount {
            case 1:  -6
            case 2:  -4
            default:  5 //+2 on the lift, so the gap to a 3-line message widens rather than rides up
        }
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
