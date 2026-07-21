//
//  InstantKeyboard.swift
//  Scoop Test
//
//  Created by Art Ostin on 20/07/2026.
//

import SwiftUI


//Mechanics to show a keyboard Instantly

/*
USE:
 
Step 1: Trigger the new screen
 
 .sheet(isPresented: $showSheet) {
     SheetSearchView()
 }
 
 .instantSlide(isPresented: $showPush) { //If showing from push
     PushSearchView(isPresented: $showPush)
 }
 
Step 2: Show the actual keyboard and adjust layout like textEditor
 
 InstantKeyboardField(text: $query)
    .padding()
    .background..
 */

enum KeyboardFocusTiming {
    /// Pop the keyboard in fully formed, without animation, on the next
    /// runloop tick. Use for sheets/fullScreenCovers and custom SwiftUI
    /// transitions — the keyboard stays live and correctly colored.
    case immediate
    /// Wait for the enclosing view controller transition to finish, then
    /// let the keyboard rise. Use for NavigationStack pushes, where an
    /// in-transition keyboard is always the gray snapshot.
    case afterTransition
}

/// A multi-line text view that summons the keyboard by itself — declare and
/// lay it out exactly like TextEditor:
///
///     InstantKeyboardField(text: $query)
///         .frame(height: 200)
///         .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.black) }
///
/// Like TextEditor it fills whatever frame you give it, wraps text from the
/// top-leading corner, scrolls when the text outgrows the frame, and has no
/// placeholder — overlay a `Text` while the binding is empty if you need one.
struct InstantKeyboardField: UIViewRepresentable {
    @Binding var text: String
    /// SwiftUI's `.font()` modifier can't reach inside a
    /// UIViewRepresentable, hence a parameter.
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var focusTiming: KeyboardFocusTiming = .immediate
    /// Insets the text from the field's edges. When set, UITextView's default
    /// 5pt line-fragment padding is zeroed so `left`/`right` land exactly —
    /// letting an external placeholder overlay line up with the typed text.
    /// `nil` keeps UITextView's own top-leading insets (TextEditor-like).
    var textContainerInset: UIEdgeInsets? = nil

    final class InstantTextView: UITextView {
        var focusTiming: KeyboardFocusTiming = .immediate
        var hasAutoFocused = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, !hasAutoFocused else { return }
            hasAutoFocused = true

            switch focusTiming {
            case .immediate:
                DispatchQueue.main.async { [weak self] in
                    UIView.performWithoutAnimation {
                        self?.becomeFirstResponder()
                    }
                }
            case .afterTransition:
                if let coordinator = parentViewController?.transitionCoordinator {
                    coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                        self?.becomeFirstResponder()
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.becomeFirstResponder()
                    }
                }
            }
        }

        private var parentViewController: UIViewController? {
            var responder: UIResponder? = next
            while let current = responder {
                if let viewController = current as? UIViewController {
                    return viewController
                }
                responder = current.next
            }
            return nil
        }
    }

    func makeUIView(context: Context) -> InstantTextView {
        let view = InstantTextView()
        view.focusTiming = focusTiming
        view.font = font
        if let inset = textContainerInset {
            view.textContainerInset = inset
            view.textContainer.lineFragmentPadding = 0
        }
        view.adjustsFontForContentSizeCategory = true
        // Transparent like TextEditor, so external .background(...) shows.
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: InstantTextView, context: Context) {
        // Only push the binding value in when it actually changed elsewhere —
        // reassigning while the user types would jump the cursor to the end.
        if view.text != text {
            view.text = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextViewDelegate {
        let text: Binding<String>

        init(text: Binding<String>) { self.text = text }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}

// MARK: - Push-like slide presentation

extension View {
    /// Presents `content` full-screen with a push-like slide from the
    /// trailing edge. Unlike a real NavigationStack push, the keyboard stays
    /// live and correctly colored throughout: under the hood this is a
    /// no-animation fullScreenCover (a context UIKit never snapshots the
    /// keyboard into) with the slide driven internally.
    ///
    /// Setting `isPresented` to false — from the parent or from a back
    /// button inside `content` — plays the slide-out, dismissing the
    /// keyboard in sync with it.
    ///
    /// Attach this to the ENTIRE presenting screen (e.g. the
    /// NavigationStack), not an inner view: the attached view is what gets
    /// pushed out toward the leading edge while the new screen slides in.
    func instantSlide<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(InstantSlideModifier(isPresented: isPresented,
                                      slideContent: content))
    }

    /// Builds the system keyboard invisibly the first time this view is on
    /// screen, so the session's first real keyboard appears instantly and
    /// fully styled. `.instantSlide` already does this; use it directly when
    /// a screen only presents keyboards via sheets or pushes.
    func keyboardPrewarmed() -> some View {
        background(KeyboardPrewarmer().frame(width: 0, height: 0))
    }
}

private struct InstantSlideModifier<SlideContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var slideContent: () -> SlideContent

    /// The cover's actual visibility outlives `isPresented` so the
    /// slide-out can play before the cover is torn down.
    @State private var coverShown = false
    @State private var isSlidIn = false
    @State private var screenWidth = UIScreen.main.bounds.width

    /// UIKit's push curve, replicated. See PushTransitionSpec for the values.
    private var pushAnimation: Animation { PushTransitionSpec.animation }

    func body(content: Content) -> some View {
        content
            .keyboardPrewarmed()
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                screenWidth = width
            }
            // The pushed-out effect: like a real push, the presenting screen
            // drifts a fraction of its width toward the leading edge while
            // the new screen slides in over it. It animates because it
            // shares the isSlidIn transaction with the cover's slide.
            .offset(x: isSlidIn ? -screenWidth * PushTransitionSpec.parallaxFraction : 0)
            .onChange(of: isPresented) { _, shown in
                if shown {
                    withTransaction(noSystemAnimation) { coverShown = true }
                } else {
                    slideOut()
                }
            }
            .fullScreenCover(isPresented: $coverShown) {
                ZStack {
                    // The dim a real push lays over the receding screen.
                    // The .opacity MODIFIER (not Color.opacity) is what
                    // guarantees a smooth animated fade in both directions.
                    Color.black
                        .ignoresSafeArea()
                        .opacity(isSlidIn ? PushTransitionSpec.dimAlpha : 0)

                    if isSlidIn {
                        slideContent()
                            // The soft shadow a real push draws along the
                            // incoming screen's leading edge.
                            .background(alignment: .leading) {
                                LinearGradient(
                                    gradient: Gradient(stops: PushTransitionSpec.edgeShadowStops),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: PushTransitionSpec.edgeShadowWidth)
                                .offset(x: -PushTransitionSpec.edgeShadowWidth)
                                .ignoresSafeArea()
                            }
                            .transition(.move(edge: .trailing))
                            // Views playing their REMOVAL transition lose
                            // their implicit z-position and would dip under
                            // the scrim during the slide-out — pin it on top.
                            .zIndex(1)
                    }
                }
                .onAppear {
                    withAnimation(pushAnimation) { isSlidIn = true }
                }
                .presentationBackground(.clear)
            }
    }

    private func slideOut() {
        // Resign focus NOW: SwiftUI keeps the view alive until the exit
        // transition finishes, so without this the keyboard would only start
        // dismissing after the slide-out. This way both animate together.
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
        withAnimation(pushAnimation) {
            isSlidIn = false
        } completion: {
            withTransaction(noSystemAnimation) { coverShown = false }
        }
    }

    /// The cover must appear/disappear with no system animation — the slide
    /// is driven by `isSlidIn`.
    private var noSystemAnimation: Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }
}

/// The measured parameters of UIKit's default navigation push, from
/// decompiled UIKit internals and the major open-source replicas
/// (SloppySwiper, react-navigation, Flutter's Cupertino route, Telegram).
private enum PushTransitionSpec {
    /// How far the outgoing screen recedes, as a fraction of its width.
    /// Decompiled _UINavigationParallaxTransition uses 0.3 (not 1/3).
    static let parallaxFraction: CGFloat = 0.3
    /// The dim over the outgoing screen: _UIParallaxDimmingView defaults to
    /// black at 0.1, riding the same curve as the slide.
    static let dimAlpha = 0.1
    /// The shadow on the incoming screen's leading edge. Real UIKit renders
    /// a 9pt GAUSSIAN BLUR falloff, which reads far softer than a linear
    /// gradient at the same peak — so the replica uses a wider strip with a
    /// blur-shaped curve and a subtle peak (Flutter's Cupertino replica
    /// settled on ~0.02 peak for the same reason).
    static let edgeShadowWidth: CGFloat = 24
    static let edgeShadowStops: [Gradient.Stop] = [
        .init(color: .clear, location: 0),
        .init(color: .black.opacity(0.003), location: 0.35),
        .init(color: .black.opacity(0.01), location: 0.7),
        .init(color: .black.opacity(0.025), location: 1),
    ]
    /// UIKit's own current push spring (decompiled iOS 18:
    /// UIViewSpringAnimationBehavior with dampingRatio 1.0, response 0.35),
    /// which SwiftUI expresses exactly as .smooth(duration: 0.35).
    static var animation: Animation { .smooth(duration: 0.35) }
}

// MARK: - Keyboard pre-warming

/// The system keyboard is built lazily on the session's first
/// becomeFirstResponder, which makes that first presentation slow and
/// briefly unstyled. Becoming and immediately resigning first responder —
/// without animation — pays that one-time cost invisibly up front.
private struct KeyboardPrewarmer: UIViewRepresentable {
    final class PrewarmField: UITextField {
        var hasPrewarmed = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, !hasPrewarmed else { return }
            hasPrewarmed = true
            UIView.performWithoutAnimation {
                becomeFirstResponder()
                resignFirstResponder()
            }
        }
    }

    func makeUIView(context: Context) -> PrewarmField { PrewarmField() }
    func updateUIView(_ uiView: PrewarmField, context: Context) {}
}
