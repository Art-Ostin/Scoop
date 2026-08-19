//
//  BlurCover.swift
//  Scoop
//
//  Created by Art Ostin on 19/08/2026.
//

import SwiftUI

/*
 Wallet-style cover: while presented, the live app underneath blurs and washes out to an
 opaque canvas, and the cover content shows above — the app is only visible during the two
 transitions, exactly as Wallet treats the home screen behind a card.

 The blur is a real BACKDROP filter (UIVisualEffectView scrubbed through a paused animator),
 never SwiftUI's `.blur` on the content: `.blur` rasterizes the subtree offscreen, which kills
 Liquid Glass surfaces outright (tab bar, popup chrome vanish and stay dead), renders the zoom
 plane's transparent host view as solid black under `opaque: true`, and can't see UIKit
 animator flights mid-collapse. The backdrop samples the live composited window instead, so
 all of those blur in place, device-verified broken on 2026-08-19 before this rewrite.

 Apply at the app root, wrapping the TabView group. The cover content brings its own entry/exit:
 attach a `.transition` to its root to animate it, or none to have it cut in/out like the
 decline cover.
 */

//Measured Wallet choreography (60fps device recording, 2026-08-19). In: one beat, blur
//front-loaded, wash slower and all the way to opaque. Out: staggered — wash clears first,
//the world sharpens last, trailing the content's exit.
enum BlurCoverMotion {
    //How far into the material the scrubbed animator goes at full presentation — the
    //fraction↔radius map is nonlinear, so this is calibrated by eye in-sim against the
    //Wallet recording rather than derived.
    static let peakFraction: CGFloat = 0.45
    static let blurIn = Animation.smooth(duration: 0.15)
    static let washIn = Animation.smooth(duration: 0.40)
    //Trails the wash by a beat, not a pause: measured A/B against Wallet (2026-08-19), the
    //resolve ramp itself matched at 0.35/0.15 but the dead tail — blurred screen with no
    //content left to watch — ran ~0.46s vs Wallet's ~0.32s, because Wallet's resolve overlaps
    //its card flight. Pulling the delay in and trimming the spring closes that gap.
    static let blurOut = Animation.smooth(duration: 0.30).delay(0.08)

    //Held as a number too: choreographies that clear themselves against the wash time off it
    static let washOutDuration = 0.22
    static let washOut = Animation.smooth(duration: washOutDuration)

    //The window the content keeps to animate itself out before the plane is torn down. Must
    //outlast the longest exit a cover runs on its own state — ResponseCoverExit.duration.
    static let contentHold: Duration = .milliseconds(360)

    //When the wash has reached opaque with margin: surfaces the cover presented over (popups,
    //zoom-presented profiles) are dismissed at this point, under the cover — never in front of
    //the user. Wallet-measured: at rest the sheet is opaque and the world only changes behind it.
    static let coveredAt: Duration = .milliseconds(650)
}

struct BlurCover<Cover: View>: ViewModifier {

    //Injected
    var isPresented: Bool
    var tint: Color
    var maxOpacity: Double
    @ViewBuilder var cover: () -> Cover

    //Local view state — held rather than derived so each leg's animation is scoped to the one
    //value it drives; `.animation(_:value:)` at this altitude would sit above the whole
    //TabView and sweep unrelated changes into the same transaction.
    @State private var blur: CGFloat = 0 //0…1 progress into peakFraction
    @State private var wash: Double = 0
    @State private var coverShown = false
    @State private var holdGeneration = 0 //Invalidates a teardown a newer presentation outran

    func body(content: Content) -> some View {
        content
            .modifier(BackdropBlurDriver(progress: blur))
            .overlay {
                tint
                    .opacity(wash)
                    //Blocks the app underneath for the whole presentation, exit included —
                    //`isPresented` alone would drop the guard while the cover is still leaving
                    .allowsHitTesting(isPresented || coverShown)
                    .ignoresSafeArea()
            }
            .overlay {
                //Mounts in the presenting transaction itself: a cover that stands in for
                //something the same tap just hid (the decline cross over its button icon)
                //can't afford the one-frame gap `coverShown` alone would add. `coverShown`
                //then holds it mounted through the exit.
                if isPresented || coverShown { cover() }
            }
            .onChange(of: isPresented, initial: true) { _, engaged in
                withAnimation(engaged ? BlurCoverMotion.blurIn : BlurCoverMotion.blurOut) {
                    blur = engaged ? 1 : 0
                }
                withAnimation(engaged ? BlurCoverMotion.washIn : BlurCoverMotion.washOut) {
                    wash = engaged ? maxOpacity : 0
                }
                //Mounted instantly, torn down late: the content animates itself out against the
                //clearing wash rather than being yanked away with it. Its own entrance and exit
                //are its business — a transition on its root, or state it drives itself.
                holdGeneration += 1
                if engaged {
                    coverShown = true
                } else if coverShown {
                    let generation = holdGeneration
                    Task {
                        try? await Task.sleep(for: BlurCoverMotion.contentHold)
                        //A newer presentation (or close) arrived mid-hold and owns the plane now
                        guard generation == holdGeneration else { return }
                        coverShown = false
                    }
                }
            }
    }
}

extension View {
    func blurCover(
        isPresented: Bool,
        tint: Color = .appCanvas,
        maxOpacity: Double = 1,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(BlurCover(isPresented: isPresented, tint: tint, maxOpacity: maxOpacity, cover: content))
    }
}

/*
 The per-frame bridge: an Animatable modifier's body re-evaluates with interpolated
 animatableData on every frame of an animation, which is what lets the paused UIKit animator
 be scrubbed in step with the SwiftUI clock — a plain @State read only updates the
 representable once per transaction, at the target value.
 */
private struct BackdropBlurDriver: ViewModifier, Animatable {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.overlay {
            BackdropBlurView(fraction: progress * BlurCoverMotion.peakFraction)
                .ignoresSafeArea()
                .allowsHitTesting(false) //The wash owns the touch guard
        }
    }
}

//A backdrop blur whose strength is a scrubbed fraction of the material — the standard paused
//UIViewPropertyAnimator technique. The effect view samples whatever the window composites
//beneath it, Liquid Glass and in-flight UIKit animations included.
private struct BackdropBlurView: UIViewRepresentable {
    var fraction: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: nil)
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        context.coordinator.scrub(to: fraction, on: view)
    }

    static func dismantleUIView(_ view: UIVisualEffectView, coordinator: Coordinator) {
        coordinator.tearDown()
    }

    @MainActor
    final class Coordinator {
        private var animator: UIViewPropertyAnimator?

        func scrub(to fraction: CGFloat, on view: UIVisualEffectView) {
            if animator == nil || animator?.state == .stopped {
                animator?.stopAnimation(true)
                view.effect = nil
                let fresh = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                    view.effect = UIBlurEffect(style: .regular)
                }
                //Never allowed to finish: a completed animator commits the full effect and
                //stops responding to fractionComplete.
                fresh.pausesOnCompletion = true
                animator = fresh
            }
            animator?.fractionComplete = min(max(fraction, 0), 1)
        }

        func tearDown() {
            animator?.stopAnimation(true)
            animator = nil
        }
    }
}

#Preview {
    @Previewable @State var covered = false
    ScrollView {
        LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: Spacing.md) {
            ForEach(0..<30) { index in
                Circle()
                    .fill([Color.accent, .dangerRed, .successGreen, .warningYellow, .actionBlue][index % 5])
            }
        }
        .padding(Spacing.margin)
        Button("Present") { covered = true }
            .font(.body(16, .medium))
    }
    .blurCover(isPresented: covered) {
        VStack(spacing: Spacing.lg) {
            Text("Covered")
                .font(.title(26))
                .foregroundStyle(Color.textPrimary)
            Button("Dismiss") { covered = false }
                .font(.body(16, .medium))
        }
        //Animates itself against the wash, the way the response cover's card does
        .opacity(covered ? 1 : 0)
        .animation(.transition, value: covered)
    }
}
