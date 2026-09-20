//
//  KeyboardDoneButton.swift
//  Scoop
//
//  Created by Art Ostin on 20/09/2026.
//

import SwiftUI

extension View {

    /// A Done button on the keyboard's own line, trailing edge: in on the blur pop a beat after the
    /// focus, out in ~20ms with the tap that ended its job.
    ///
    /// The line is MEASURED, never inferred from the safe area — UIKit reports the keyboard's frame
    /// before the keyboard moves, so the button is placed while it is still hidden and never animates
    /// up from the screen's foot. That is also why this takes the screen's keyboard avoidance with it:
    /// the foot the inset counts down from has to be the screen's own, so the system's push is refused
    /// here (after the overlay — placed before it, a region that shrinks for the keyboard moves the
    /// overlay's origin before the overlay's own ignore can undo it).
    ///
    /// A screen that still needs its content to move for the keyboard lifts it itself, on `.keyboard`:
    ///
    ///     content
    ///         .offset(y: isFocused ? -Spacing.lg : 0)
    ///         .animation(.keyboard, value: isFocused)
    ///         .keyboardDoneButton(isFocused: $isFocused)
    ///
    /// - Parameters:
    ///   - title: the button's word. "Done" unless a screen has a better one.
    ///   - isFocused: the field's focus. Tapping resigns it; the button follows it in and out.
    ///   - hide: how it leaves. `.vanish` by default — ~20ms, gone before the keyboard has visibly
    ///     moved, which is right where Done and the keyboard leave on the same tap. A screen whose Done
    ///     should read as a control being put away rather than snatched passes `.dismiss`.
    ///   - onDone: anything the screen wants to do besides resign — committing a draft, closing a sheet.
    func keyboardDoneButton(_ title: String = "Done",
                            isFocused: FocusState<Bool>.Binding,
                            hide: Animation = .vanish,
                            onDone: (() -> Void)? = nil) -> some View {
        modifier(KeyboardDoneButton(title: title, isFocused: isFocused, hide: hide, onDone: onDone))
    }
}

// MARK: - The accessory

/// Everything the line costs: the keyboard's frame, this screen's foot, and the beat Done waits before
/// it shows. Mirrors `EventZoomChoreo`'s keyboard accessory, which does the same arithmetic inside the
/// event zoom's own plane — the two must not drift.
private struct KeyboardDoneButton: ViewModifier {

    //Injected
    let title: String
    var isFocused: FocusState<Bool>.Binding
    let hide: Animation
    let onDone: (() -> Void)?

    //Local view state
    @State private var showsDone = false        //Done's own flag: in a beat after the focus, out with the resign
    //Where a PRESENTED keyboard's top last stood, global: Done's line. A keyboard on its way out never
    //moves it — the control pops away where it stands
    @State private var keyboardTop: CGFloat?
    //This screen's own foot and width, global, measured with the keyboard's inset already refused: what
    //the inset counts down from, and what tells a docked keyboard from a floating one
    @State private var screenBottom: CGFloat = .infinity
    @State private var screenWidth: CGFloat = 0

    //Held until the keyboard's spring is ~85% home (`.keyboard` is .smooth(0.2667) on iOS 26), so Done
    //does not pop in over a keyboard still sliding up beneath it. Out the instant focus resigns —
    //asymmetric on purpose
    private static let lag: Duration = .milliseconds(120)
    //The keyboard's top ↔ Done's foot, exactly
    private static let keyboardClearance: CGFloat = Spacing.sm

    func body(content: Content) -> some View {
        content
            //Screen coordinates, which this full-screen view's global space matches. The SAME view the
            //overlay hangs on, so the foot the inset is measured against is the foot its padding counts from
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { screen in
                screenWidth = screen.width
                screenBottom = screen.maxY
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
                guard (note.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool) ?? true,
                      let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                report(end)
            }
            .overlay(alignment: .bottomTrailing) { button }
            //AFTER the overlay, never before and never inside it (measured: before the overlay the card
            //still shifted its full 155.5pt, after it, nothing)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onChange(of: isFocused.wrappedValue) { _, focused in
                if !focused { showsDone = false } //Out with the resign itself
            }
            .task(id: isFocused.wrappedValue) {
                guard isFocused.wrappedValue else { return }
                try? await Task.sleep(for: Self.lag)
                if !Task.isCancelled { showsDone = true }
            }
    }
}

// MARK: - The line, and what stands on it

private extension KeyboardDoneButton {

    //Done's foot above this screen's own: the keyboard as it last stood, and the clearance over it. No
    //keyboard seen (a hardware one reports none on screen): the clearance alone, and Done takes the
    //screen's foot
    var inset: CGFloat {
        guard let keyboardTop, screenBottom.isFinite else { return Self.keyboardClearance }
        return max(screenBottom - keyboardTop, 0) + Self.keyboardClearance
    }

    //UIKit's keyboard frame, which arrives BEFORE the keyboard moves — so the line is known while Done is
    //still hidden and the inset is taken bare. Only a DOCKED keyboard on this screen is a line to stand
    //on: a floating or undocked one reports a narrow or off-screen frame. A keyboard on its way OUT never
    //moves the line
    func report(_ end: CGRect) {
        let docked = !end.isEmpty && end.maxY >= screenBottom - 1 && end.width >= screenWidth - 1
        guard docked, end.minY < screenBottom, keyboardTop != end.minY else { return }
        keyboardTop = end.minY //Bare: the curve is the `.animation` below's to pick
    }

    var button: some View {
        ScoopButton(style: .tinted(.black, shadow: nil, glass: true), shape: Capsule()) { //Pure .black, NOT .blackFill: a design call (2026-09-18) — never "fix" it back to the token
            isFocused.wrappedValue = false
            onDone?()
        } label: {
            Text(title)
                .font(.body(14, .bold))
                .padding(Spacing.sm)
                .padding(.horizontal, Spacing.xxs)
        }
        .blurPop(visible: showsDone, hide: hide) //In on the pop's spring; out on the caller's exit — `.vanish` unless a screen wants it slower
        .padding(.trailing, Spacing.lg)
        .padding(.bottom, inset)
        //Nil while hidden is the important half: the first inset write lands during the lag, so Done takes
        //its line bare and never animates up from the screen's foot. `.keyboard` while visible covers a
        //keyboard that changes height mid-field (predictive bar, a language switch, emoji)
        .animation(showsDone ? .keyboard : nil, value: inset)
    }
}
