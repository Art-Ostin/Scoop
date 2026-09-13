//
//  RespondNoteReveal.swift
//  Scoop
//
//  Created by Art Ostin on 13/09/2026.
//
//  The respond card's note reveal, all in one place: focused, the note is a scroll, and pulling it down brings Hello Worlds into view.
//

import SwiftUI

private typealias Spec = RespondNoteRevealSpec

//The note and its Done come from RespondToMessageBar; the room to grow into comes from RespondToInviteContainer
struct RespondNoteReveal<Note: View, Pinned: View>: View {

    //Injected
    let isFocused: FocusState<Bool>.Binding
    let text: String //The note's text: typing brings a pulled note back into view
    let restHeight: CGFloat //The note as it lays out at rest, its foot inset included
    let note: Note
    let pinned: Pinned //The note's Done: hung under the note's resting foot, never scrolled
    @Environment(\.noteRevealRoom) private var room //How far the focused scroll grows up over the rows

    //Local view state
    @State private var position = ScrollPosition(y: Spec.helloWorldsHeight) //Resting on the note, the Hello Worlds parked above it
    @State private var tracker = RevealTracker(offset: Spec.helloWorldsHeight) //The live offset, read on resign; a class so scrolling never re-renders
    @State private var fadedOut = false //A resign from a pull hides the reveal while it re-seats

    
    init(isFocused: FocusState<Bool>.Binding, text: String, restHeight: CGFloat, @ViewBuilder note: () -> Note, @ViewBuilder pinned: () -> Pinned) {
        self.isFocused = isFocused
        self.text = text
        self.restHeight = restHeight
        self.note = note()
        self.pinned = pinned()
    }

    //The height the scroll grows up by: the rows' room while focused, none at rest
    private var growth: CGFloat { isFocused.wrappedValue ? room : 0 }

    var body: some View {
        scroll
            .overlay(alignment: .topTrailing) {
                pinned
                    .padding(.top, Spec.glassBleed + restHeight + Spacing.xs) //Under the resting note's foot: Done never scrolls
                    .padding(.trailing, Spacing.lg)
            }
            .padding(.top, -(Spec.glassBleed + growth)) //Grows up over the rows, never down: the card's height holds
    }
}

//The scroll: the Hello Worlds, the note, and a runway under it
extension RespondNoteReveal {

    private var scroll: some View {
        ScrollView {
            VStack(spacing: 0) {
                helloWorlds
                Color.clear.frame(height: Spec.glassBleed)
                note
                Color.clear.frame(height: room + Spec.slack) //Runway: as tall as the growth, plus the slack past the resting spot
            }
            .padding(.horizontal, Spacing.lg)
        }
        .frame(height: Spec.glassBleed + restHeight + growth)
        .opacity(fadedOut ? 0 : 1)
        .scrollPosition($position)
        .scrollTargetBehavior(RevealRest(rest: Spec.helloWorldsHeight))
        .defaultScrollAnchor(UnitPoint(x: 0.5, y: Spec.helloWorldsHeight / (Spec.helloWorldsHeight + room - growth + Spec.slack)), for: .initialOffset)
        .scrollDisabled(!isFocused.wrappedValue)
        .scrollDismissesKeyboard(.never)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
            tracker.offset = y
            guard !isFocused.wrappedValue, !fadedOut, abs(y - Spec.helloWorldsHeight) > 0.5 else { return }
            reseat()
        }
        .onChange(of: isFocused.wrappedValue) { _, focused in
            if focused {
                position.isPositionedByUser = true //Clears the stored point, so the next re-seat is always a real change
            } else if tracker.offset < Spec.helloWorldsHeight - 0.5 {
                returnFromPull()
            }
        }
        .onChange(of: text) {
            //Typing into a pulled note brings it back into view
            guard isFocused.wrappedValue, tracker.offset < Spec.helloWorldsHeight - 0.5 else { return }
            withAnimation(.move) { position.scrollTo(y: Spec.helloWorldsHeight) }
        }
        .onScrollPhaseChange { _, phase, context in
            //A resign that raced a bounce can leave the resting scroll off the note: put it back once it settles
            guard phase == .idle, !isFocused.wrappedValue,
                  abs(context.geometry.contentOffset.y - Spec.helloWorldsHeight) > 0.5 else { return }
            withAnimation(.move) { position.scrollTo(y: Spec.helloWorldsHeight) }
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
        withTransaction(instant) { position.scrollTo(y: Spec.helloWorldsHeight) }
    }

    // TODO: the reveal's real content replaces these placeholder rows
    private var helloWorlds: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<Spec.helloWorldCount, id: \.self) { _ in
                Text("Hello World")
                    .font(.body(16, .medium))
                    .foregroundStyle(Color.textSecondary)
                    .frame(height: Spec.helloWorldRowHeight)
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true) //Placeholders: VoiceOver landing on one would scroll the note away
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
    static let glassBleed: CGFloat = Spacing.sm //Headroom above the glass inside the scroll; focused, the glass's gap under the photo
    static let helloWorldCount = 12 //The placeholder rows a focused pull brings down from above the note
    static let helloWorldRowHeight: CGFloat = Spacing.xl
    static var helloWorldsHeight: CGFloat { CGFloat(helloWorldCount) * helloWorldRowHeight }
    static let slack: CGFloat = Spacing.md //Room past the resting spot, so the note's own growth never clamps the offset low

    //How far the focused scroll may grow up over rows this tall: all of them, less the bleed it keeps under the photo
    static func room(over rowsHeight: CGFloat) -> CGFloat { max(rowsHeight - glassBleed, 0) }
}

//A release that would come to rest past the note's resting spot ends on it instead
private struct RevealRest: ScrollTargetBehavior {
    let rest: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        target.rect.origin.y = min(target.rect.origin.y, rest)
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
