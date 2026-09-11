//
//  MessageBubble.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit

//The one set of numbers the resting bubble, the composer and the send flight's clone all read, so the
//typed line and the sent line share a face and their insets: the text neither changes font nor jumps
//on the frame the composer becomes the bubble.
enum BubbleMetrics {
    static let fontSize: CGFloat = 16
    static let weight: Font.bodyFontWeight = .medium
    static var font: Font { .body(fontSize, weight) }
    //Scaled the way the Text it measures scales: `.custom(_:size:)` follows Dynamic Type relative to the body style
    static var uiFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .body(fontSize, weight)) }
    static let lineSpacing: CGFloat = 5
    static let leading = Spacing.md
    static let trailing = Spacing.md
    static let vertical: CGFloat = 10 //Geometry: centres the 16 pt line in a 36 pt one-line bubble
    //The draft field's own top and bottom inset: its one line sits level with the send button beside it
    static var fieldVertical: CGFloat { max(0, (ButtonSize.large.size - uiFont.lineHeight) / 2) }
    static let runGap = Spacing.sm //Clearance under the last bubble of a run, where its tail hangs
    static let badgeRow = Spacing.sm //The extra line a wrapped bubble opens under its text for the hour badge
    static let badgeGap = Spacing.labelGap //Between the inline hour badge and the text's last glyph
    static var cornerRadius: CGFloat { MessageBubbleShape().messageCornerRadius } //The shape owns its measured radius
    //A one-line bubble body: ModernEra's line height is its point size
    static var singleLineHeight: CGFloat { uiFont.lineHeight + vertical * 2 }
    //The empty draft field: the same line in the field's own insets
    static var fieldSingleLineHeight: CGFloat { uiFont.lineHeight + fieldVertical * 2 }
}

struct MessageBubbleView: View {

    //Injected
    let chat: ChatMessage
    let nextIsNewAuthor: Bool
    let isMyChat: Bool
    //The scroll container's width, so the hour badge's placement is right on the first layout pass instead of
    //one pass later (a 12 pt height snap a send flight landing on the row cannot pre-empt)
    var containerWidth: CGFloat = 0
    var showsTime: Bool = true //False while the message waits on the server or its send flight is still landing: a clock
    var onBodyFrame: ((CGRect) -> Void)? = nil //The bubble body's frame in the chat space, for a flight's landing

    //Local view state
    @State private var measured: BadgePlacement?

    var body: some View {
        let placement = self.placement
        Text(chat.content)
            .font(BubbleMetrics.font)
            .foregroundStyle(isMyChat ? Color.white : Color.textPrimary)
            .lineSpacing(BubbleMetrics.lineSpacing)
            .padding(.leading, BubbleMetrics.leading)
            .padding(.trailing, BubbleMetrics.trailing + placement.reservation)
            .padding(.vertical, BubbleMetrics.vertical)
            .padding(.bottom, placement.isBelow ? BubbleMetrics.badgeRow : 0)
            .background(bubbleShape.fill(isMyChat ? Color.accent : Color.fillGray))
            .background(bodyFrameReporter)
            .overlay(alignment: .bottomTrailing) { hourMessageSent }
            .frame(maxWidth: .infinity, alignment: isMyChat ? .trailing : .leading)
            .background(columnMeasure)
            //Own bubbles end on the send button's trailing line (Spacing.gutter): a sent bubble is born on the draft field
            //and its trailing edge travels out to that line as it contracts; received ones keep the margin
            .padding(.leading, isMyChat ? Self.openSide : Spacing.margin)
            .padding(.trailing, isMyChat ? Spacing.gutter : Self.openSide)
            .padding(.bottom, nextIsNewAuthor ? BubbleMetrics.runGap : 0)
    }
}

//The hour badge's placement
extension MessageBubbleView {

    struct BadgePlacement: Equatable {
        var isBelow: Bool //Under the text, on its own line
        var reservation: CGFloat //Trailing room kept beside a one-line text for the inline badge
    }

    //Measured once the row lays out; before that, derived from the container, so the first pass is already right
    private var placement: BadgePlacement {
        if let measured { return measured }
        guard containerWidth > 0 else { return BadgePlacement(isBelow: true, reservation: 0) }
        let column = Self.columnWidth(containerWidth: containerWidth, isMyChat: isMyChat)
        return Self.timePlacement(text: chat.content, maxBubbleWidth: column, date: chat.dateCreated ?? Date())
    }

    private var columnMeasure: some View {
        Color.clear
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                let next = Self.timePlacement(text: chat.content, maxBubbleWidth: width, date: chat.dateCreated ?? Date())
                if measured != next { measured = next }
            }
    }
}

//Resting geometry, computed the way the body lays out — so a row's height and width are known before it exists
extension MessageBubbleView {

    private static let openSide = Spacing.margin + Spacing.xxl //The side a bubble leaves open, opposite its author

    //The width a bubble may grow to inside a row of the given container width
    static func columnWidth(containerWidth: CGFloat, isMyChat: Bool) -> CGFloat {
        max(0, containerWidth - openSide - (isMyChat ? Spacing.gutter : Spacing.margin))
    }

    //Where the hour badge goes: inline after a one-line text (reserving its width), else under the text when
    //the last line leaves no room beside it
    static func timePlacement(text: String, maxBubbleWidth: CGFloat, date: Date) -> BadgePlacement {
        let timeWidth = inlineTimeBadgeWidth(for: date)
        let inlineWidth = max(0, maxBubbleWidth - BubbleMetrics.leading - BubbleMetrics.trailing - timeWidth)
        let inline = textLayoutMetrics(text: text, width: inlineWidth, font: BubbleMetrics.uiFont)
        if inline.lineCount <= 1 { return BadgePlacement(isBelow: false, reservation: timeWidth) }
        let wrapWidth = max(0, maxBubbleWidth - BubbleMetrics.leading - BubbleMetrics.trailing)
        let wrap = textLayoutMetrics(text: text, width: wrapWidth, font: BubbleMetrics.uiFont)
        return BadgePlacement(isBelow: wrap.trailingSpace < timeWidth, reservation: 0)
    }

    //The bubble body at rest (the tail hangs below it), for a text sent into a column of this width. The send
    //flight lands on it and the row grows to it.
    static func restingSize(text: String, maxBubbleWidth: CGFloat, date: Date) -> CGSize {
        let placement = timePlacement(text: text, maxBubbleWidth: maxBubbleWidth, date: date)
        let textWidth = max(0, maxBubbleWidth - BubbleMetrics.leading - BubbleMetrics.trailing - placement.reservation)
        let layout = textLayoutSize(text: text, width: textWidth, font: BubbleMetrics.uiFont, lineSpacing: BubbleMetrics.lineSpacing)
        let width = ceil(layout.width) + BubbleMetrics.leading + BubbleMetrics.trailing + placement.reservation
        let height = ceil(layout.height) + BubbleMetrics.vertical * 2 + (placement.isBelow ? BubbleMetrics.badgeRow : 0)
        return CGSize(width: width, height: height)
    }

    static func inlineTimeBadgeWidth(for date: Date) -> CGFloat {
        let attr = NSAttributedString(
            string: FormatEvent.hourTime(date),
            attributes: [
                .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .body(10, .regular)),
                .kern: 1
            ]
        )
        return ceil(attr.size().width) + BubbleMetrics.badgeGap
    }
}

//Components
extension MessageBubbleView {

    private var hourMessageSent: some View {
        MessageTimeBadge(date: chat.dateCreated ?? Date(), showsTime: showsTime, isMyChat: isMyChat)
    }

    private var bubbleShape: MessageBubbleShape {
        MessageBubbleShape(tail: nextIsNewAuthor ? (isMyChat ? .trailing : .leading) : .none)
    }

    private var bodyFrameReporter: some View {
        Color.clear
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ChatUIState.space)) } action: { onBodyFrame?($0) }
    }
}

//The bubble's time, or a clock while the message waits on the server. Sized by the time either way, so the bubble never
//changes width when the clock gives way; the swap is a blur replace. The send flight's clone wears it too, clock from birth.
struct MessageTimeBadge: View {
    let date: Date
    let showsTime: Bool
    let isMyChat: Bool

    var body: some View {
        timeText
            .opacity(0) //Holds the time's size while the clock shows
            .accessibilityHidden(true)
            .overlay(alignment: .trailing) {
                ZStack(alignment: .trailing) {
                    if showsTime {
                        timeText
                            .transition(.blurReplace)
                    } else {
                        Image(systemName: "clock")
                            .font(.icon(10, .regular))
                            .accessibilityLabel("Sending")
                            .transition(.blurReplace)
                    }
                }
                .animation(.transition, value: showsTime)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .foregroundStyle(isMyChat ? Color.white.opacity(0.7) : Color.textTertiary)
    }

    private var timeText: some View {
        Text(FormatEvent.hourTime(date))
            .font(.body(10, .regular))
            .kerning(1)
    }
}

//Where a wrapped text's lines fall, laid out the way the bubble draws it (same face, same line spacing)
func textLayoutMetrics(text: String, width: CGFloat, font: UIFont, lineSpacing: CGFloat = BubbleMetrics.lineSpacing) -> (lineCount: Int, trailingSpace: CGFloat) {
    guard !text.isEmpty, width > 0 else { return (1, width) }
    let layout = textLayout(text: text, width: width, font: font, lineSpacing: lineSpacing)

    var lineCount = 0
    var lastUsedRect = CGRect.zero
    let glyphs = layout.manager.glyphRange(for: layout.container)
    layout.manager.enumerateLineFragments(forGlyphRange: glyphs) { _, usedRect, _, _, _ in
        lineCount += 1
        lastUsedRect = usedRect
    }
    withExtendedLifetime(layout.storage) {}

    return (max(1, lineCount), max(0, width - lastUsedRect.maxX))
}

//The text's laid-out size: the widest line by its lines, with the bubble's spacing between them
func textLayoutSize(text: String, width: CGFloat, font: UIFont, lineSpacing: CGFloat) -> CGSize {
    guard !text.isEmpty, width > 0 else { return CGSize(width: 0, height: font.lineHeight) }
    let layout = textLayout(text: text, width: width, font: font, lineSpacing: lineSpacing)
    let string = layout.storage.string as NSString

    var lineCount = 0
    var widest: CGFloat = 0
    let glyphs = layout.manager.glyphRange(for: layout.container)
    layout.manager.enumerateLineFragments(forGlyphRange: glyphs) { _, _, _, lineGlyphs, _ in
        lineCount += 1
        //A wrapped line's used rect runs through the space it broke at (sim: 280 pt reported for a 261 pt line), so
        //its width is measured on its glyphs without the trailing whitespace
        var chars = layout.manager.characterRange(forGlyphRange: lineGlyphs, actualGlyphRange: nil)
        while chars.length > 0, let last = UnicodeScalar(string.character(at: chars.location + chars.length - 1)),
              CharacterSet.whitespacesAndNewlines.contains(last) {
            chars.length -= 1
        }
        guard chars.length > 0 else { return }
        let trimmed = layout.manager.glyphRange(forCharacterRange: chars, actualCharacterRange: nil)
        widest = max(widest, layout.manager.boundingRect(forGlyphRange: trimmed, in: layout.container).maxX)
    }
    withExtendedLifetime(layout.storage) {}
    lineCount = max(1, lineCount)
    return CGSize(width: widest, height: CGFloat(lineCount) * font.lineHeight + CGFloat(lineCount - 1) * lineSpacing)
}

//The storage is returned with the manager: a layout manager only holds its text storage weakly, so a
//storage that dies with the helper's scope leaves the manager with no glyphs to enumerate
private func textLayout(text: String, width: CGFloat, font: UIFont, lineSpacing: CGFloat) -> (storage: NSTextStorage, manager: NSLayoutManager, container: NSTextContainer) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = lineSpacing
    paragraph.lineBreakStrategy = .standard //SwiftUI's Text pushes a word down rather than orphan the last one; wrap as it does
    let attr = NSAttributedString(
        string: text,
        attributes: [
            .font: font,
            .paragraphStyle: paragraph
        ]
    )
    let storage = NSTextStorage(attributedString: attr)
    let manager = NSLayoutManager()
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    container.lineBreakMode = .byWordWrapping

    storage.addLayoutManager(manager)
    manager.addTextContainer(container)
    manager.ensureLayout(for: container)
    return (storage, manager, container)
}
