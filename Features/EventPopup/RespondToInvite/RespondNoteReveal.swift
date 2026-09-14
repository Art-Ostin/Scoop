//
//  RespondNoteReveal.swift
//  Scoop
//
//  Created by Art Ostin on 13/09/2026.
//
//  The respond card's note reveal, all in one place: focused, the note is a scroll, and pulling it down brings the past messages into view.
//

import SwiftUI

private typealias Spec = RespondNoteRevealSpec

//The note and its Done come from RespondToMessageBar; the room to grow into comes from RespondToInviteContainer
struct RespondNoteReveal<Note: View, Pinned: View>: View {

    //Injected
    //Logic to display the past messages
    let eventHistory: [PastEventProposal]?
    let userId: String
    let otherUserId: String
    
    
    let isFocused: FocusState<Bool>.Binding
    let text: String //The note's text: typing brings a pulled note back into view
    let restHeight: CGFloat //The note as it lays out at rest, its foot inset included
    let note: Note
    let pinned: Pinned //The note's Done: hung under the note's resting foot, never scrolled
    @Environment(\.noteRevealRoom) private var room //How far the focused scroll grows up over the rows

    //Local view state
    @State private var position = ScrollPosition(y: 0) //Resting on the note, the history parked above it
    @State private var tracker = RevealTracker(offset: 0) //The live offset, read on resign; a class so scrolling never re-renders
    @State private var historyHeight: CGFloat = 0 //The past messages as they lay out, measured: the block above the note, so a pull stops at the oldest one
    @State private var fadedOut = false //A resign from a pull hides the reveal while it re-seats

    
    init(
        eventHistory: [PastEventProposal]?,
        userId: String,
        otherUserId: String,
        isFocused: FocusState<Bool>.Binding,
        text: String,
        restHeight: CGFloat,
        @ViewBuilder note: () -> Note,
        @ViewBuilder pinned: () -> Pinned
    ) {
        self.eventHistory = eventHistory
        self.userId = userId
        self.otherUserId = otherUserId
        self.isFocused = isFocused
        self.text = text
        self.restHeight = restHeight
        self.note = note()
        self.pinned = pinned()
    }

    //The offset every rest parks at: the note under the past messages, less the starting pull's share of the room above them.
    //Focused, the block grows by the pull, so the scroll's own top sits the top padding above the oldest message: both ends are
    //real edges, and a flick into either keeps its momentum and bounces (nothing retargets a release — a changed target glides)
    private var restOffset: CGFloat { rest(over: historyHeight) }

    //The rest offset over a history this tall, never above the scroll's own top
    private func rest(over height: CGFloat) -> CGFloat {
        let count = extractMessages().count
        return max(height + Spec.topPadding(for: count) - Spec.startingPull(for: count), 0)
    }

    //The slack kept past the furthest rest: all of it at rest; focused, none once the starting pull covers it, so the note under the photo is the scroll's real end
    private var runwaySlack: CGFloat { max(Spec.slack - pull, 0) }

    //The height the scroll grows up by: the rows' room while focused, none at rest
    private var growth: CGFloat { isFocused.wrappedValue ? room : 0 }

    //How far the focused note starts pulled down, as if the user had pulled it: the history grows by this above its bubbles,
    //so the last bubble and the note slide down together. The resting offset never moves, so a resign needs no scroll of its own
    private var pull: CGFloat { isFocused.wrappedValue ? Spec.startingPull(for: extractMessages().count) : 0 }

    var body: some View {
        scroll
            .overlay(alignment: .topTrailing) {
                pinned
                    .padding(.top, Spec.glassBleed + restHeight + Spacing.xs) //Under the resting note's foot: Done never scrolls, and the starting pull is a scroll
                    .padding(.trailing, Spacing.lg)
            }
            .padding(.top, -(Spec.glassBleed + growth)) //Grows up over the rows, never down: the card's height holds
    }
}

//The scroll: the past messages, the note, and a runway under it
extension RespondNoteReveal {

    private var scroll: some View {
        ScrollView {
            VStack(spacing: 0) {
                messageSection
                Color.clear.frame(height: Spec.glassBleed)
                note
                Color.clear.frame(height: room + runwaySlack) //Runway: as tall as the growth, plus any slack the starting pull doesn't already keep past the resting spot
            }
            .padding(.horizontal, Spacing.lg)
        }
        .frame(height: Spec.glassBleed + restHeight + growth)
        .opacity(fadedOut ? 0 : 1)
        .scrollPosition($position)
        .defaultScrollAnchor(UnitPoint(x: 0.5, y: restOffset / (restOffset + pull + room - growth + runwaySlack)), for: .initialOffset)
        .scrollDisabled(!isFocused.wrappedValue)
        .scrollDismissesKeyboard(.never)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
            tracker.offset = y
            guard !isFocused.wrappedValue, !fadedOut, abs(y - restOffset) > 0.5 else { return }
            reseat()
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.height } action: { _, _ in
            //A resting history that resized without its offset following (a write the scroll never took): back onto the note
            guard !isFocused.wrappedValue, !fadedOut, abs(tracker.offset - restOffset) > 0.5 else { return }
            reseat()
        }
        .onChange(of: isFocused.wrappedValue) { _, focused in
            if focused {
                position.isPositionedByUser = true //Clears the stored point, so the next re-seat is always a real change
            } else if abs(tracker.offset - restOffset) > 0.5 {
                returnFromPull() //Pulled further down, or pushed back up past the starting pull
            }
        }
        .onChange(of: text) {
            //Typing into a pulled note brings it back into view
            guard isFocused.wrappedValue, tracker.offset < restOffset - 0.5 else { return }
            withAnimation(.move) { position.scrollTo(y: restOffset) }
        }
        .onScrollPhaseChange { _, phase, context in
            //A resign that raced a bounce can leave the resting scroll off the note: put it back once it settles
            guard phase == .idle, !isFocused.wrappedValue,
                  abs(context.geometry.contentOffset.y - restOffset) > 0.5 else { return }
            withAnimation(.move) { position.scrollTo(y: restOffset) }
        }
    }

    //A pull can't glide home with the card's resign, so the reveal fades out, re-seats unseen and fades back in
    private func returnFromPull() {
        withAnimation(.quick, completionCriteria: .logicallyComplete) {
            fadedOut = true
        } completion: {
            if !isFocused.wrappedValue { reseat() } //A refocus inside the fade keeps the pull where it is
            withAnimation(.transition) { fadedOut = false }
        }
    }

    //Straight back onto the note, with no motion of its own
    private func reseat() {
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) { position.scrollTo(y: restOffset) }
    }

    //The past messages laid out at a new height (their first measure, or a rewrap as the card's width changes): the block and the
    //offset move together in one instant write, so the note stays exactly where it is and every rest still parks on it
    private func resize(history height: CGFloat) {
        guard abs(height - historyHeight) > 0.5 else { return }
        let offset = tracker.offset + rest(over: height) - restOffset //The rest's own shift: less than the height's when floored at the top
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            historyHeight = height
            position.scrollTo(y: offset)
        }
    }

    private var messageSection: some View {
        VStack(spacing: 0) {
            ForEach(extractMessages(), id: \.self) { chatMessage in
                let isMyChat = chatMessage.authorId == userId
                MessageBubbleView(chat: chatMessage, nextIsNewAuthor: true, isMyChat: isMyChat, isInviteMessage: true)
                    .padding(.leading, isMyChat ? 0 : -Spec.receivedPull)
            }
        }
        .padding(.horizontal, -Spacing.lg)
        .fixedSize(horizontal: false, vertical: true) //Its own height, never the block's: measured inside the block, the bubbles would squeeze to fit it
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { resize(history: $0) }
        .frame(height: restOffset + pull, alignment: .bottom) //Exactly the rest offset tall, so every rest parks on the note. The pull grows it from the top, so the last bubble rides down with the note
    }
    
    private func extractMessages() -> [ChatMessage] {
        guard let eventHistory else { return [] }
        return eventHistory.compactMap { pastEventProposal in
            guard let message = pastEventProposal.message, !message.isEmpty else { return nil } //Blank counts as none, as it does for the lift
            let authorId = pastEventProposal.senderId
            let recipientId = authorId == userId ? otherUserId : userId
            return ChatMessage(authorId: authorId, recipientId: recipientId, content: message)
        }
    }
}

//The container's half: the rows the scroll grows over slide up behind the photo, out of reach of taps and VoiceOver
extension View {
    func noteRevealRows(isFocused: Bool, room: CGFloat) -> some View {
        offset(y: isFocused ? -room : 0)
            .allowsHitTesting(!isFocused) //Under the photo's edge while lifted: a clip hides, it does not fence
            .accessibilityHidden(isFocused)
    }
}

//The reveal's measures
enum RespondNoteRevealSpec {
    static let glassBleed: CGFloat = Spacing.sm //Headroom above the glass inside the scroll; focused, the glass's gap under the photo before the starting pull
    //How far the focused note starts pulled down, by how many past messages there are: raise a case to start it lower.
    //Only the starting scroll: the gap between the last bubble and the note doesn't change, and a push takes it back up. Keep every
    //case at least `slack` (16): a shallower pull leaves the push-up end past the note under the photo
    static func startingPull(for count: Int) -> CGFloat {
        switch count {
        case 0: Spacing.md + Spacing.xxs //No past messages: 20
        case 1: Spacing.xxl //One: 48
        default: Spacing.xxl + 10 //2 or more, the photo riding higher: 58
        }
    }
    //The blank between the oldest message and the scroll's own top, by how many past messages there are: a full pull stops there with
    //iOS's own bounce. Raise a case for more room under the photo (a history shorter than the starting pull shows more)
    static func topPadding(for count: Int) -> CGFloat {
        switch count {
        case 0, 1: 0
        default: Spacing.xl //2 or more: 36
        }
    }
    static let slack: CGFloat = Spacing.md //The least room past the resting spot, so the note's own growth never clamps the offset low
    //Geometry: a received bubble still clears the chat's photo column (33.7 pt in at Large) where a sent one ends a gutter off
    //its edge; pulled out by the difference, both sit a gutter in. Follows the text size, as that column does
    static var receivedPull: CGFloat { MessageBubbleView.receivedLeading(isInviteMessage: true) - Spacing.gutter }

    //How far the focused scroll may grow up over rows this tall: all of them, less the bleed it keeps under the photo
    static func room(over rowsHeight: CGFloat) -> CGFloat { max(rowsHeight - glassBleed, 0) }

    //How much higher the focused card rides once the history holds more than one message: the photo's foot rises by this
    //and its top slides further off the screen, so the photo still fills it. One message or none stays at the shell's pin
    static let historyLift: CGFloat = Spacing.xl
    static func lift(over eventHistory: [PastEventProposal]?) -> CGFloat {
        messageCount(in: eventHistory) > 1 ? historyLift : 0
    }

    //The past messages the reveal draws above the note: a blank one counts as none, as it does in `extractMessages`
    static func messageCount(in eventHistory: [PastEventProposal]?) -> Int {
        (eventHistory ?? []).count(where: { $0.message?.isEmpty == false })
    }
}

//The reveal's live offset: written every scroll frame, read only on resign
private final class RevealTracker {
    var offset: CGFloat
    init(offset: CGFloat) { self.offset = offset }
}

extension EnvironmentValues {
    @Entry var noteRevealRoom: CGFloat = 0 //How far the focused note's scroll may grow up over the rows
}
