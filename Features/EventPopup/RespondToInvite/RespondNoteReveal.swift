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
    //The messages drawn above the note: the retired rounds and the live proposal, oldest first
    let thread: [PastEventProposal]
    let userId: String
    let otherUserId: String
    
    
    let isFocused: FocusState<Bool>.Binding //The raw focus: what the scroll's own rules read (reach, re-seats, the return from a pull)
    let isOpen: Bool //The focus as the MOTION reads it: the card's ride, flipped in one transaction on the keyboard's spring (the container's `rideNote`). Everything here that moves keys on it
    let text: String //The note's text: typing brings what is being written back into view
    let restHeight: CGFloat //The note as it lays out at rest, its foot inset included
    let noteFootInset: CGFloat //How much of the OPEN note's height is the gap under its glass: what a measure of the note has to come off to be the glass's own foot. Read only while open — resting as its bubble, a written note keeps another gap
    let textDepth: CGFloat //How far below the glass's top the last line of the note's text in view ends
    let note: Note
    let pinned: Pinned //The note's Done: hung under the note's resting foot, never scrolled
    @Environment(\.noteRevealRoom) private var room //How far the focused scroll grows up over the rows
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo? //The zoom the card stands in: how wide the focused card will be
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    //Local view state
    @State private var position = ScrollPosition(y: 0) //Resting on the note, the history parked above it
    @State private var tracker = RevealTracker(offset: 0) //The live offset, read on resign; a class so scrolling never re-renders
    @State private var historyHeight: CGFloat = 0 //The past messages as they lay out, measured: the block above the note, so a pull stops at the oldest one
    @State private var fadedOut = false //A resign from a pull hides the reveal while it re-seats
    @State private var lift: CGFloat = 0 //The ride's follow-through, 0 → 1 → 0: the thread and the note land a few points past their place and ease back
    @State private var frames = RevealFrames() //Where the note and the window it is seen through stand on screen; a class, so a ride or a scroll never re-renders this view to report them
    @State private var mutesSentFill = false //A close from where the thread opened: the sent bubbles ride home over the rows in the received gray


    init(
        thread: [PastEventProposal],
        userId: String,
        otherUserId: String,
        isFocused: FocusState<Bool>.Binding,
        isOpen: Bool,
        text: String,
        restHeight: CGFloat,
        noteFootInset: CGFloat = 0,
        textDepth: CGFloat = 0,
        @ViewBuilder note: () -> Note,
        @ViewBuilder pinned: () -> Pinned
    ) {
        self.thread = thread
        self.userId = userId
        self.otherUserId = otherUserId
        self.isFocused = isFocused
        self.isOpen = isOpen
        self.text = text
        self.restHeight = restHeight
        self.noteFootInset = noteFootInset
        self.textDepth = textDepth
        self.note = note()
        self.pinned = pinned()
    }

    //The offset every rest parks at: the note under the past messages, less the starting pull's share of the room above them.
    //Focused, the block grows by the pull, so the scroll's own top sits the top padding above the oldest message: both ends are
    //real edges, and a flick into either keeps its momentum and bounces (nothing retargets a release — a changed target glides)
    private var restOffset: CGFloat { rest(over: historyHeight) }

    //The scroll parked where the thread opens, the last bubble right above the note: a close from here rides the thread
    //home, a close from anywhere else is a return from a pull, and fades
    private var restsOnNote: Bool { abs(tracker.offset - restOffset) <= 0.5 }

    //The rest offset over a history this tall, never above the scroll's own top
    private func rest(over height: CGFloat) -> CGFloat {
        max(height + Spec.topPadding - Spec.startingPull(for: extractMessages().count), 0)
    }

    //The slack kept past the furthest rest: all of it at rest; focused, none once the starting pull covers it, so the note under the photo is the scroll's real end
    private var runwaySlack: CGFloat { max(Spec.slack - pull, 0) }

    //The height the scroll grows up by: the rows' room once the note is open, none at rest
    private var growth: CGFloat { isOpen ? room : 0 }

    //How far the open note starts pulled down, as if the user had pulled it: the history grows by this above its bubbles,
    //so the last bubble and the note slide down together. The resting offset never moves, so a resign needs no scroll of its own
    private var pull: CGFloat { isOpen ? Spec.startingPull(for: extractMessages().count) : 0 }

    //The width the open card will stand at, known while it still rests narrower: the thread lays out at it from the start.
    //0 outside a zoom (or before its plane has laid out): the thread then takes the card's own width
    private var threadWidth: CGFloat { flight?.keyboardCardWidth ?? 0 }

    //The note's own slot is all the card's layout ever sees of the reveal, open or not: the scroll and Done hang off it.
    //Off a plain view, not off the scroll: a ScrollView's frame is re-laid out on every frame of a ride, and Done hung
    //on it reported its foot to the shell sixty times a ride — each report a fresh re-pin, the drop forever chasing
    var body: some View {
        Color.clear
            .frame(height: restHeight)
            .overlay(alignment: .top) {
                scroll
                    .offset(y: -Spec.followThrough * lift) //The thread and the note only: Done holds the keyboard's line
                    .alignmentGuide(.top) { _ in Spec.glassBleed + growth } //Grows up over the rows, never down: the card's height holds
            }
            .overlay(alignment: .topTrailing) {
                pinned
                    .padding(.trailing, Spacing.lg)
                    .alignmentGuide(.top) { _ in growth - restHeight - Spacing.xs } //Under the resting note's foot, up with the scroll's top: Done never scrolls, and the starting pull is a scroll
            }
            .onChange(of: isOpen) { _, open in
                followThrough(open)
                muteSentFill(open)
            }
    }

    //A close from where the thread opened rides the last bubbles down through the rows' band as the rows resolve under
    //them, and a sent bubble's accent read there as a pink block over them: it takes the received gray as it goes, well
    //inside its dissolve. A close from a pull fades out whole and keeps it. The accent is back as the note opens, the
    //thread still dissolved
    private func muteSentFill(_ open: Bool) {
        let mutes = !open && restsOnNote
        guard mutes != mutesSentFill else { return }
        withAnimation(Spec.sentFillMute) { mutesSentFill = mutes }
    }

    //The ride's landing: what the card carries keeps going a few points once the card has stopped, and eases back (the
    //event zoom's landing breath, on the keyboard's clock). The rise ends flat, so the settle leaves from rest at its
    //peak: issued from the rise's completion, the two are one motion. Not both in this turn — here a second write in
    //the same turn folds the pair into no change at all (rig, 2026-09-17). A close is flat; reduce motion never lifts
    private func followThrough(_ open: Bool) {
        guard open, !reduceMotion else {
            if lift != 0 { withAnimation(.keyboard) { lift = 0 } } //A close is flat: a rise still in flight turns for home with the card
            return
        }
        withAnimation(.followThroughRise, completionCriteria: .logicallyComplete) {
            lift = 1
        } completion: {
            withAnimation(.followThroughSettle) { lift = 0 }
        }
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
                    //Where the note IS, the scroll's own offset folded in — its layout slot is the card's, points below.
                    //Into a class, read on a keystroke: written every frame of a ride and every frame of a scroll, a
                    //@State here would re-render the whole reveal with it
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames.note = $0 }
                Color.clear.frame(height: room + runwaySlack) //Runway: as tall as the growth, plus any slack the starting pull doesn't already keep past the resting spot
            }
            .padding(.horizontal, Spacing.lg)
            .background { KeyboardClampHold() } //In the content, outside the note: its nearest scroll is this one, not the note's own
        }
        .frame(height: Spec.glassBleed + restHeight + growth)
        //The window the reveal is seen through: its top is the photo's foot (the container's clip), its foot the card's
        //own clip under the note's slot. The frame, not the content: scrolling never moves it
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames.window = $0 }
        .opacity(fadedOut ? 0 : 1)
        //The scroll's top edge travels with the ride, a bleed above the rows' foot: clipped to it, the thread rose cut flat
        //by a line nobody could see, the place row riding on the cut (device, 2026-09-17). The container's own clip — the
        //photo's foot — is the only edge the thread ever meets: it slides under the photo, as a pull's does
        .scrollClipDisabled()
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
            } else if !restsOnNote {
                returnFromPull() //Pulled further down, or pushed back up past the starting pull
            }
        }
        .onChange(of: text) { keepTextInView() }
        //A keystroke that wraps lands a beat before the text re-measures: the new line is only there to be seen once it has.
        //Growth only — the ride's own pad change (12 → 8 as the field opens) shrinks it
        .onChange(of: textDepth) { old, new in
            if new > old + 0.5 { keepTextInView() }
        }
        .onScrollPhaseChange { _, phase, context in
            //A resign that raced a bounce can leave the resting scroll off the note: put it back once it settles
            guard phase == .idle, !isFocused.wrappedValue,
                  abs(context.geometry.contentOffset.y - restOffset) > 0.5 else { return }
            withAnimation(.move) { position.scrollTo(y: restOffset) }
        }
    }

    //What the user is writing stays readable. A note a pull (or a push) has taken mostly out of sight (`typingReturnShare`)
    //goes back to where it opened; short of that the thread stays where they put it, moving only as far as the last line of
    //their text needs to clear Done — a peek at the history survives, and so does their third line
    private func keepTextInView() {
        //A line break lives one pass: it is the Return key closing the note (Done's path, which moves nothing here) or a
        //paste the bar turns into a space, and that pass comes back without it. Its own line is never there to be read
        guard isFocused.wrappedValue, isOpen, !text.contains(where: \.isNewline) else { return }
        if abs(tracker.offset - restOffset) > 0.5, noteHiddenShare >= Spec.typingReturnShare {
            withAnimation(.move) { position.scrollTo(y: restOffset) }
            return
        }
        let shortfall = textShortfall
        guard shortfall > 0.5 else { return }
        //Never past the scroll's real end (the note under the photo): a scroll written beyond it would stand there, not bounce
        withAnimation(.move) { position.scrollTo(y: min(tracker.offset + shortfall, restOffset + pull + runwaySlack)) }
    }

    //How far the last line in view of the note's text sits below what it must clear — Done's top, standing on the keyboard's
    //line (the keyboard itself, with no Done drawn; the card's own clip should that come first) — `textClearance` of air
    //included: what the thread must move up by for all of it to be read, its trailing end included (Arthur, 2026-09-18)
    private var textShortfall: CGFloat {
        let note = frames.note, window = frames.window
        guard note.height > 1, window.height > 1 else { return 0 }
        let foot = min(window.maxY, flight?.keyboardAccessoryTop ?? flight?.keyboardLine ?? .infinity)
        return note.minY + textDepth + Spec.textClearance - foot
    }

    //How much of the note's glass, where it stands this instant, lies out of sight: above the window's top (the photo's foot, a
    //push) or below its foot — the keyboard's line, or the card's own clip should that come first (a pull, to read the thread).
    //Nothing measured yet: all of it, so typing returns as it always did
    private var noteHiddenShare: CGFloat {
        let note = frames.note, window = frames.window
        let glassTop = note.minY, glassFoot = note.maxY - noteFootInset
        guard glassFoot - glassTop > 1, window.height > 1 else { return 1 }
        let foot = min(window.maxY, flight?.keyboardLine ?? .infinity)
        let shown = max(min(glassFoot, foot) - max(glassTop, window.minY), 0)
        return 1 - shown / (glassFoot - glassTop)
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

    //The past messages laid out at a new height (their first measure, a new message, a text size change — never a ride: they
    //stand at the open card's width from the start): the block and the offset move together in one instant write, so the
    //note stays exactly where it is and every rest still parks on it
    private func resize(history height: CGFloat) {
        guard abs(height - historyHeight) > 0.5 else { return }
        let offset = tracker.offset + rest(over: height) - restOffset //The rest's own shift: less than the height's when floored at the top
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            historyHeight = height
            position.scrollTo(y: offset)
            tracker.offset = offset //Where the scroll is being put: a second measure in the same pass (the zoom's width landing a pass after the mount) must shift from here, not from the last offset the scroll reported
        }
    }

    //The block above the note: exactly the rest offset tall, so every rest parks on the note; the pull grows it from the top,
    //so the last bubble rides down with the note. The bubbles hang in it, off its foot, at the OPEN card's width from the
    //start: laid out at the card's own width they re-flowed on every frame of its widening — the last line re-broke twice in
    //its final 2.5pt, the badge hopped a row, and each change of height fired an instant `resize` mid-ride (device,
    //2026-09-17). An overlay, so the wider block never widens the scroll's content (and the note with it): at rest it
    //overhangs the card a gap a side, out of sight — no ink in its gutters, and the thread is dissolved there anyway
    private var messageSection: some View {
        Color.clear
            .frame(height: restOffset + pull)
            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    ForEach(extractMessages(), id: \.self) { chatMessage in
                        let isMyChat = chatMessage.authorId == userId
                        MessageBubbleView(chat: chatMessage, nextIsNewAuthor: true, isMyChat: isMyChat, isInviteMessage: true,
                                          mutesSentFill: mutesSentFill,
                                          containerWidth: threadWidth) //The badge's row is right on the first pass, not a pass (and 12pt) later
                            .offset(x: isMyChat ? 0 : -Spec.receivedPull) //Not a negative padding: that widens the row, and a row's width sets its widest bubble
                    }
                }
                .padding(.horizontal, threadWidth > 0 ? 0 : -Spacing.lg) //No zoom around it: the card's own width, out past the scroll's margins
                .frame(width: threadWidth > 0 ? threadWidth : nil)
                .fixedSize(horizontal: false, vertical: true) //Its own height, never the block's: measured inside the block, the bubbles would squeeze to fit it
                //Measured only at the width it keeps: inside a zoom that lands a pass after the mount, and a first measure at
                //the card's own width moved the offset twice in that pass — the scroll kept the second, the tracker the
                //first, and every Done from rest then read as a return from a pull, and faded (rig, 2026-09-17)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                    if flight == nil || abs(size.width - threadWidth) < 0.5 { resize(history: size.height) }
                }
                //The thread and the rows share one band of the card, so the ride is a swap: the rows dissolve as they leave
                //(`noteRevealRows`), the thread resolves as it rises with the note — and back. Scoped to the look alone:
                //the block's own growth stays on the ride's spring
                .animation(isOpen ? Spec.threadIn : Spec.threadOut) {
                    $0.opacity(isOpen ? 1 : 0)
                        .blur(radius: isOpen ? 0 : Spec.swapBlur)
                }
                .accessibilityHidden(!isOpen) //Dissolved at rest: nothing for VoiceOver to land on
            }
    }
    
    private func extractMessages() -> [ChatMessage] {
        thread.compactMap { proposal in
            guard let message = proposal.message, !message.isEmpty else { return nil } //Blank counts as none, as it does for the lift
            let authorId = proposal.senderId
            let recipientId = authorId == userId ? otherUserId : userId
            var chat = ChatMessage(authorId: authorId, recipientId: recipientId, content: message)
            chat.dateCreated = proposal.dateSent //The round's own stamp: the corner reads the day it was sent, not today
            return chat
        }
    }
}

//The container's half: the rows the scroll grows over leave up under the photo, dissolving as they go, out of reach of
//taps and VoiceOver. The slide rides the transaction that flips `isOpen` (the ride's); the dissolve keeps its own, shorter
//clock, so the rows are gone before the thread, rising into the band they held, has resolved — and on the way back they
//resolve once it has cleared
extension View {
    func noteRevealRows(isOpen: Bool, isFocused: Bool, room: CGFloat) -> some View {
        animation(isOpen ? RespondNoteRevealSpec.rowsOut : RespondNoteRevealSpec.rowsIn) {
            $0.opacity(isOpen ? 0 : 1)
                .blur(radius: isOpen ? RespondNoteRevealSpec.swapBlur : 0)
        }
        .offset(y: isOpen ? -room : 0)
        .allowsHitTesting(!isFocused && !isOpen) //Under the photo's edge while lifted: a clip hides, it does not fence
        .accessibilityHidden(isFocused || isOpen)
    }
}

//The reveal's measures
enum RespondNoteRevealSpec {
    //The ride's swap, rows ⇄ thread: whichever leaves is dismissed at once, whichever arrives resolves a beat into the
    //ride, once the band it takes has begun to clear — the card's own body swap, on a shorter lag (this one is moving)
    static let rowsOut: Animation = .dismiss
    static let threadIn: Animation = .transition.delay(swapLag)
    static let threadOut: Animation = .dismiss
    static let rowsIn: Animation = .transition.delay(swapLag)
    static let swapLag: TimeInterval = 0.06
    static let swapBlur: CGFloat = 6 //The card's body swap's: a full-width block at the house 8 reads as a rack-focus
    //A sent bubble's accent giving way to the gray as the thread rides home, on a clock two `swapLag`s long: ~70% gray as
    //the rows begin to resolve under it (`rowsIn`), ~90% by the time they show, all of it at 0.12s — the thread then ~85%
    //dissolved (`threadOut`). A shorter `swapLag` or a slower dissolve leaves more of the accent over the returning rows
    static let sentFillMute: Animation = .quick
    //How far past their place the thread and the note land before they ease back (`.followThroughRise`/`Settle`): the
    //card itself stops dead with the keyboard. Raise it for a livelier landing
    static let followThrough: CGFloat = 4

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
    //The blank between the oldest message and the scroll's own top, where a full pull stops with iOS's own bounce: as deep as
    //the gap the thread keeps at its other end, under the last bubble (its `runGap` plus the `glassBleed` over the note), so
    //the messages sit in an even band under the photo. One message used to get none of it and its bubble met the photo's
    //edge; two or more got Spacing.xl, which read as a hole (Arthur, 2026-09-17)
    static let topPadding: CGFloat = Spacing.lg
    static let slack: CGFloat = Spacing.md //The least room past the resting spot, so the note's own growth never clamps the offset low
    //How much of the note's glass must be out of sight before typing brings the thread back to where it opened. Short of
    //this the user can still see what they are writing, and a keystroke leaves the thread where they put it: a peek at the
    //history survives, a pull that has buried the field does not (Arthur, 2026-09-18)
    static let typingReturnShare: CGFloat = 0.8
    //The air kept between the last line of the note's text and Done's top when typing nudges the thread to show it
    static let textClearance: CGFloat = Spacing.xs
    //Geometry: a received bubble still clears the chat's photo column (33.7 pt in at Large) where a sent one ends a gutter off
    //its edge; pulled out by the difference, both sit a gutter in. Follows the text size, as that column does
    static var receivedPull: CGFloat { MessageBubbleView.receivedLeading(isInviteMessage: true) - Spacing.gutter }

    //How far the focused scroll may grow up over rows this tall: all of them, less the bleed it keeps under the photo
    static func room(over rowsHeight: CGFloat) -> CGFloat { max(rowsHeight - glassBleed, 0) }

    //How much higher the focused card rides past the shell's pin, by how many messages sit above the note: the photo's foot
    //rises by this and its top slides further off the screen, so the photo still fills it. A thread pushes the note down by
    //its `startingPull`, and Done stands on the keyboard's line whatever the card does — so without this the note's glass
    //runs under Done (measured: 7.6pt with one message, whose 48pt pull is more than twice the 20pt a bare note starts at)
    static func lift(over thread: [PastEventProposal]) -> CGFloat {
        switch messageCount(in: thread) {
        case 0: 0 //The note starts barely pulled: its glass clears Done on the pin alone
        case 1: Spacing.md //16
        default: Spacing.xl //2 or more, their block deeper again: 36
        }
    }

    //The past messages the reveal draws above the note: a blank one counts as none, as it does in `extractMessages`
    static func messageCount(in thread: [PastEventProposal]) -> Int {
        thread.count(where: { $0.message?.isEmpty == false })
    }
}

//The keyboard stretches this scroll's bounds to the screen's foot, with a safe-area inset to match. As it leaves, UIKit strips the
//inset before SwiftUI has shrunk the bounds back: for that instant no offset above the top is legal, UIKit clamps it
//(`_adjustContentOffsetIfNecessary`), and as all of it happens inside the keyboard's own animation block, the clamp is ANIMATED, on
//the keyboard's curve. SwiftUI's re-seat lands a pass later, outside the block: the offset is right again, the clamp's animation
//still plays on top of it — the note leapt up by the whole offset and sank for 0.38s, or the thread rolled down through the card
//(rig, 2026-09-17). Put back here, inside the same block, the clamp's animation and the restore's cancel exactly, and SwiftUI never
//sees the offset leave: the tracker still reads the rest, so a resign from rest doesn't fade. Watches the scroll view itself, as
//`PageHoldOnResize` does; a finger, a deceleration and SwiftUI's own scrollTo all run outside an animation block, and are left alone
private struct KeyboardClampHold: UIViewRepresentable {

    final class MarkerView: UIView {
        private var observation: NSKeyValueObservation?
        private var restoring = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            observation = nil
            guard window != nil else { return }
            var view: UIView? = superview
            while let current = view, !(current is UIScrollView) { view = current.superview }
            guard let scroll = view as? UIScrollView else { return }
            observation = scroll.observe(\.contentOffset, options: [.old, .new]) { [weak self] scroll, change in
                MainActor.assumeIsolated { self?.offsetChanged(scroll, from: change.oldValue, to: change.newValue) }
            }
        }

        private func offsetChanged(_ scroll: UIScrollView, from old: CGPoint?, to new: CGPoint?) {
            guard !restoring, let old, let new, new.y < old.y - 0.5, UIView.inheritedAnimationDuration > 0,
                  !scroll.isTracking, !scroll.isDragging, !scroll.isDecelerating else { return }
            //…and onto the bottom limit of the bounds as they stand, still stretched: nothing else lands exactly there
            let limit = max(scroll.contentSize.height + scroll.adjustedContentInset.bottom - scroll.bounds.height, -scroll.adjustedContentInset.top)
            guard abs(new.y - limit) < 0.5 else { return }
            restoring = true
            scroll.contentOffset = old //Inside the same block: an equal and opposite animation. The bounds shrink next, and the offset is legal again
            restoring = false
        }
    }

    func makeUIView(context: Context) -> MarkerView {
        let view = MarkerView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: MarkerView, context: Context) {}
}

//Where the note's own view (its foot inset included) and the reveal's window stand on screen, global: written whenever the
//card lays out or the scroll moves, read only on a keystroke
private final class RevealFrames {
    var note: CGRect = .zero
    var window: CGRect = .zero
}

//The reveal's live offset: written every scroll frame, read only on resign
private final class RevealTracker {
    var offset: CGFloat
    init(offset: CGFloat) { self.offset = offset }
}

extension EnvironmentValues {
    @Entry var noteRevealRoom: CGFloat = 0 //How far the focused note's scroll may grow up over the rows
}
