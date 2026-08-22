//
//  ToolbarButtons.swift
//  Scoop
//
//  Created by Art Ostin on 11/07/2026.


import SwiftUI


struct InfoButton: View {
    @Binding var showScreen: Bool
    var isAtTopOfScroll: Bool = true
    
    var body: some View {
        ScoopButton(shape: Circle(), size: .medium, action: {showScreen = true}) {
            Image(systemName: "info.circle")
                .font(.body(18, .medium))
        }
        .blurPop(visible: isAtTopOfScroll)
        .padding(.top, Spacing.md) //As its small icon, sits in correct position
        .padding(.horizontal, Spacing.margin)
    }
}


//Created here as frozen & Blocked view need it
struct SettingsButton: View {
    let action: () -> ()
    var body: some View {
        ScoopButton(shape: Circle(), size: .medium, action: action) {
            Image("SettingsIcon")
                .font(.body(14, .medium))
                .foregroundStyle(Color.black)
        }
    }
}


extension ToolbarContent {
    @ToolbarContentBuilder
    func hideToolbarBackground() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            self
                .sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}


// iOS 26 draws a glass "platter" behind every toolbar item, and that platter is a hard 44×44:
// no content size, `controlSize`, or `buttonSizing` moves it (all four sim-measured). Hiding it
// with `sharedBackgroundVisibility(.hidden)` and drawing our own glass circle does resize the
// button, but it costs the zoom transition its spring — the `.zoom` flight reads the PLATTER as
// its source, and with one present it overshoots +1.5% at t≈0.30 and settles by 0.53s, while
// without one it becomes a monotone ease with no overshoot and a long tail. So the platter has
// to stay, and gets scaled instead: the glass renders at `size`, its content is counter-scaled
// back to its natural point size, and the flight starts from the smaller circle on the very same
// curve. Pre-26 — and if the platter is ever renamed — there is nothing to find and this no-ops.
//
// `visible` is `blurPop` reassembled across the SwiftUI/UIKit seam. A SwiftUI opacity can only
// reach the label — the glass is UIKit's, and dimming the label alone leaves an empty circle
// sitting in the bar — so the label keeps the blur and the platter itself wears the scale and
// the fade. Both ride ONE spring: the driver is `Animatable`, so its body re-evaluates with an
// interpolated `progress` every frame (a plain flag would reach UIKit once, at the target).
// Dropping the item from the toolbar instead was measured too — it cuts, with no animation at all.
//
// The blur is label-only and always will be: `PlatterGlassView` is the label's ANCESTOR, so no
// SwiftUI layer effect below it can reach the lens. That is why the two halves do NOT share one
// curve — the platter's alpha runs on `PopMotion.lensCutoff` so the lens is gone in the first
// stretch of the spring, the way `blurPop`'s glass died on its first blurred frame, while the
// shrink carries on to the end underneath it.
extension View {
    func toolbarPlatter(size: CGFloat, visible: Bool = true) -> some View {
        blur(radius: visible ? 0 : PopMotion.blurRadius)
            .allowsHitTesting(visible) //Stays mounted while hidden, so gate taps
            .modifier(ToolbarPlatter(size: size, progress: visible ? 1 : 0))
            .animation(PopMotion.spring, value: visible)
    }
}

private struct ToolbarPlatter: ViewModifier, Animatable {

    let size: CGFloat
    var progress: CGFloat //1 fully out, 0 fully away

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.background(PlatterProbe(size: size, progress: progress).frame(width: 0, height: 0))
    }
}

private struct PlatterProbe: UIViewRepresentable {

    let size: CGFloat
    let progress: CGFloat

    func makeUIView(context: Context) -> Probe { Probe(size: size, progress: progress) }
    func updateUIView(_ probe: Probe, context: Context) { probe.apply(progress) }

    final class Probe: UIView {

        private let size: CGFloat
        private var progress: CGFloat //Seeded at make: `didMoveToWindow` can beat the first update

        init(size: CGFloat, progress: CGFloat) {
            self.size = size
            self.progress = progress
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func didMoveToWindow() { super.didMoveToWindow(); apply(progress) }
        override func layoutSubviews() { super.layoutSubviews(); apply(progress) } //The bar re-lays out as the title collapses

        //Idempotent: `bounds` ignores the transform, so re-running it can't compound the scale.
        func apply(_ progress: CGFloat) {
            self.progress = progress
            guard size > 0 else { return }
            var content: UIView?
            var view: UIView? = self
            while let current = view {
                let name = String(describing: type(of: current))
                //Walking up, the glass is reached before the platter that owns it.
                if name.contains("PlatterGlassView") { content = current.subviews.first }
                if name.contains("PlatterView") {
                    let box = current.bounds
                    guard box.height > 0 else { return }
                    let fit = size / box.height
                    let pop = PopMotion.platterShrunkScale + (1 - PopMotion.platterShrunkScale) * progress
                    //Clamped because the spring undershoots below 0 on the way out and overshoots
                    //past 1 on the way back in; the lens has no headroom either side.
                    let fade = (progress / PopMotion.lensCutoff).clamped(to: 0...1)
                    //Scale about the centre, then push back so the TRAILING edge stays where the
                    //system put it — a bar button's inset is measured off its glass, not its box.
                    let shrink = CGAffineTransform(scaleX: fit * pop, y: fit * pop)
                        .concatenating(CGAffineTransform(translationX: box.width * (1 - fit) / 2, y: 0))
                    if current.transform != shrink { current.transform = shrink }
                    if current.alpha != fade { current.alpha = fade }
                    //Undo only the SIZE fit — the pop shrink is meant to carry the label with it.
                    let restore = CGAffineTransform(scaleX: 1 / fit, y: 1 / fit)
                    if let content, content.transform != restore { content.transform = restore }
                    return
                }
                view = current.superview
            }
        }

    }
}
