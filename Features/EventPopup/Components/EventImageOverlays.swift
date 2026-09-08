//
//  EventImageOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

let imageHorizontalPadding = Spacing.lg
let imageBottomPadding = Spacing.xs
let imageTopPadding = Spacing.xs

//Overlays
struct EventTitle: View {

    //Injected
    let title: String
    var textRect: Binding<CGRect> = .constant(.zero)
    var coordSpace: String? = nil

    ///The size this title lands at. A static because the event zoom's name morph lays its flying
    ///word out at the size it will land in — the two can never drift into a step at the hand-off.
    static func size(for title: String) -> CGFloat { title.starts(with: "Invite") ? 22 : 18 }

    ///How far behind the line's slide the arriving word pops in. The gap it lands in has already
    ///opened by then, so the move reads as the cause and the word as the consequence.
    private static let popDelay: TimeInterval = 0.1

    var body: some View {
        titleLine
            .foregroundStyle(Color.white)
            .animation(.transition, value: title)
            .getRect(textRect, coordSpace: coordSpace) //Inside the padding: the glyphs, not the slot
            .padding(.horizontal, imageHorizontalPadding)
            .padding(.bottom, imageBottomPadding)
    }
}

//The line, and the one word that survives a change of title
extension EventTitle {

    //Every invite title spells "Invite"; anything else (an event's own name) has no word to keep and
    //swaps whole
    @ViewBuilder
    private var titleLine: some View {
        if let words = TitleWords(title) {
            morphingLine(words)
        } else {
            Text(title)
                .font(.title(Self.size(for: title), .bold))
                .id(title)
                .transition(.blurReplace)
        }
    }

    ///"Invite" is mounted once and never replaced — inserting "Confirm" ahead of it is what slides it
    ///along, and the invitee's name takes the line's width with it as it goes. Both are one animation:
    ///the words that leave and arrive carry the move, they don't cover a swap.
    private func morphingLine(_ words: TitleWords) -> some View {
        let size = Self.size(for: title)
        return HStack(alignment: .firstTextBaseline, spacing: Self.gap(at: size)) {
            if let leading = words.leading { Text(leading).transition(pop) }

            Text(words.shared)

            if let trailing = words.trailing { Text(trailing).transition(pop) }
        }
        .animatableTitle(size)
        .contentTransition(.opacity) //Crossfades an "Invite"/"invite" case flip instead of popping it
    }

    //Out on the beat, in a beat late: the gap is open before the word that fills it shows up. Shrunk
    //toward the baseline it sits on, so a popping word never floats off its own line
    private var pop: AnyTransition {
        .asymmetric(
            insertion: .blurPop(anchor: .bottomLeading).animation(.transition.delay(Self.popDelay)),
            removal: .blurPop(anchor: .bottomLeading).animation(.transition))
    }

    ///The font's own space advance, so three runs measure exactly as the one string would: the event
    ///zoom derives its flying word's landing from `Text(title)`'s metrics and must not find a wider
    ///line here. It steps ~1pt as the size changes — under the word that is blurring out of that gap.
    private static func gap(at size: CGFloat) -> CGFloat {
        (" " as NSString).size(withAttributes: [.font: UIFont.title(size, .bold)]).width
    }
}

///An invite title split around the word every invite title shares. `nil` for a line that hasn't got
///one — it has nothing to keep, so it swaps whole.
private struct TitleWords {

    let leading: String? //What pushes "Invite" along the line: "Confirm" on the confirm screen, "Sarah's" on a received one
    let shared: String   //Spelt as the title spells it, so the case is the title's call, not this type's
    let trailing: String? //The invitee, while the send is still being composed

    ///Matched as a whole word: a bare substring match splits "Invited Sarah" into "Invite" and
    ///"d Sarah", and the space advance the runs are laid out with prints it as "Invite d Sarah".
    init?(_ title: String) {
        guard let word = title.range(of: #"\bInvite\b"#, options: [.regularExpression, .caseInsensitive]) else { return nil }
        let before = title[..<word.lowerBound].trimmingCharacters(in: .whitespaces)
        let after = title[word.upperBound...].trimmingCharacters(in: .whitespaces)
        leading = before.isEmpty ? nil : before
        shared = String(title[word])
        trailing = after.isEmpty ? nil : after
    }
}

///Point sizes tween, `.font` values don't: a plain font swap snaps to the new size on frame one and
///the line jumps out from under the word that is meant to be sliding.
private struct AnimatableTitleFont: ViewModifier, Animatable {

    var size: CGFloat
    var weight: Font.titleFontWeight = .bold

    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content.font(.title(size, weight))
    }
}

private extension View {

    func animatableTitle(_ size: CGFloat, _ weight: Font.titleFontWeight = .bold) -> some View {
        modifier(AnimatableTitleFont(size: size, weight: weight))
    }
}

struct EventImagePagerIndicator: View {
    let imageCount = 6
    let progress: Double
    
    var body: some View {
        ImagePageIndicator(count: 6, progress: progress, activeColor: .white)
            .scaleEffect(0.7, anchor: .bottomTrailing)
            .padding(.horizontal, imageHorizontalPadding)
            .padding(.bottom, imageBottomPadding)
    }
}

struct EventBackButton: View {

    //Always mounted, never self-gated: `.eventZoomBandChrome(visible:)` at the call site is the
    //one gate — the page's condition ANDed with the flight's hand-off.
    @Binding var showConfirmScreen: Bool?
    ///The copy the event zoom flies in on its cover: the same label wearing the same surface, with no
    ///Button under it. Interactive glass claims hitTest whatever the SwiftUI around it yields, so a live
    ///twin would fire this action from a tap on the flying corner ([[project_ios26_glass_hittest_stall]]).
    var inert: Bool = false

    var body: some View {
        surface
            .padding(.horizontal, imageHorizontalPadding - 4) //Geometry: as the title — one shared inset from the artwork edge
            .padding(.top, imageTopPadding)
    }

    //One style for both forms, so the twin can never drift from the button it stands in for
    private static let style: ScoopButtonStyle = .clearGlass

    @ViewBuilder
    private var surface: some View {
        if inert {
            label
                .scoopGlassSurface(clear: Self.style == .clearGlass, shape: Circle())
                .glassFallbackRestingShadow()
        } else {
            ScoopButton(style: Self.style, shape: Circle(), action: { withAnimation(.transition) { showConfirmScreen = false } }) {
                label
            }
        }
    }

    private var label: some View {
        Image(systemName: "chevron.left")
            .font(.body(17))
            .fontWeight(.heavy)
            .foregroundStyle(Color.black)
            .frame(width: 38, height: 38)
    }
}

struct NewEventToggleButton: View {
    @Binding var responseType: ResponseType
    @Binding var showConfirmScreen: Bool?
    var inert: Bool = false

    private var isNewEvent: Bool { responseType == .newEvent }

    var body: some View {
        surface
            .padding()
    }

    //One style for both forms, so the twin can never drift from the button it stands in for
    private static let style: ScoopButtonStyle = .clearGlass

    @ViewBuilder
    private var surface: some View {
        if inert {
            label
                .scoopGlassSurface(clear: !isNewEvent, shape: .capsule)
                .glassFallbackRestingShadow() //See EventBackButton.surface
        } else {
            ScoopButton(style: isNewEvent ? .glass : .clearGlass, shape: .capsule) {
                withAnimation(.transition) {
                    responseType = isNewEvent ? .originalInvite : .newEvent
                    showConfirmScreen = false
                }
            } label: {
                label
            }
        }
    }

    private var label: some View {
        HStack(spacing: Spacing.xxs) {
            if !isNewEvent {
                Image(systemName: "plus")
                    .font(.body(12, .bold))
            }

            Text(isNewEvent ? "Original Invite" : "New Invite")
                .font(.body(11, .bold))
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 7)
        .foregroundStyle(Color.textPrimary)
    }
}

struct OptionsMenu: View {
    //Always mounted, never self-gated: `.eventZoomBandChrome(visible:)` at the call site gates it
    let hasChanges: Bool
    let onClear: () -> Void
    let onDecline: () -> Void

    var body: some View {
        Menu {
            if hasChanges {
                Button(action: onClear) { Label("Clear Invite Draft", image: "BinIcon") }
            }

            Button(role: .destructive, action: onDecline) {
                Label("Decline Profile", systemImage: "xmark")
            }
        } label: {
            HStack(spacing: 3) {
                ForEach(0..<3) { _ in
                    Circle().frame(width: 4, height: 4)
                }
            }
            .foregroundStyle(.white.opacity(0.8))
            .buttonSize(.small)
            .scoopGlassSurface(clear: true, shape: .circle)
            .expandHitArea()
            .padding(.horizontal, imageHorizontalPadding - 4)
            .padding(.top, imageTopPadding)
        }
    }
}
