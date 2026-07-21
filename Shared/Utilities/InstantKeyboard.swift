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

/// A multi-line text view that summons the keyboard by itself — declare and
/// lay it out exactly like TextEditor:
///
///     InstantKeyboardField(text: $query)
///         .frame(height: 200)
///         .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.black) }
///
/// Like TextEditor it fills whatever frame you give it, wraps text from the
/// top-leading corner, and scrolls when the text outgrows the frame.
struct InstantKeyboardField: UIViewRepresentable {
    @Binding var text: String
    var textLimit: Int = 130
    var placeholder: String? = nil
    var placeholderLineSpacing: CGFloat = 6
    var placeholderFont: UIFont = .body(18, .regular)
    var placeholderColor: UIColor = .placeholderText
    /// UIKit font applied to the underlying text view.
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var lineSpacing: CGFloat = 7
    var kerning: CGFloat = 0.4
    var scrollEnabledAfterLineCount: Int? = nil
    var textContainerInset: UIEdgeInsets? = nil
    var isFocused: Binding<Bool>? = nil

    final class InstantTextView: UITextView {
        var hasAutoFocused = false
        var wantsFocus = true
        private var focusRequest = 0

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, !hasAutoFocused, wantsFocus else { return }
            hasAutoFocused = true

            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil, self.wantsFocus else { return }
                UIView.performWithoutAnimation {
                    self.becomeFirstResponder()
                }
            }
        }

        override func willMove(toWindow newWindow: UIWindow?) {
            if newWindow == nil {
                cancelFocus()
            }
            super.willMove(toWindow: newWindow)
        }

        func cancelFocus() {
            focusRequest &+= 1
            wantsFocus = false
            if isFirstResponder {
                resignFirstResponder()
            }
        }

        func applyControlledFocus() {
            focusRequest &+= 1
            let request = focusRequest

            if wantsFocus {
                attemptFocus(request: request, remainingAttempts: 10)
            } else if isFirstResponder {
                resignFirstResponder()
            }
        }

        private func attemptFocus(request: Int, remainingAttempts: Int) {
            guard request == focusRequest,
                  wantsFocus,
                  window != nil,
                  !isFirstResponder else { return }

            guard !becomeFirstResponder(), remainingAttempts > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.attemptFocus(
                    request: request,
                    remainingAttempts: remainingAttempts - 1
                )
            }
        }
    }

    func makeUIView(context: Context) -> InstantTextView {
        let view = InstantTextView()
        view.wantsFocus = isFocused?.wrappedValue ?? true
        view.text = text
        view.font = font
        applyTextStyle(to: view)
        applyTextContainerInset(to: view)
        view.adjustsFontForContentSizeCategory = true
        view.alwaysBounceVertical = false
        // Keep UITextView scrolling enabled for stable intrinsic sizing and wrapping.
        // Gate only its pan gesture when a line threshold is configured.
        view.isScrollEnabled = true
        view.panGestureRecognizer.isEnabled = scrollEnabledAfterLineCount == nil
        // Transparent like TextEditor, so external .background(...) shows.
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        context.coordinator.configurePlaceholder(
            in: view,
            text: placeholder,
            lineSpacing: placeholderLineSpacing,
            font: placeholderFont,
            color: placeholderColor
        )
        context.coordinator.updatePlaceholderVisibility(in: view)
        scheduleScrollUpdate(for: view, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ view: InstantTextView, context: Context) {
        // Only push the binding value in when it actually changed elsewhere —
        // reassigning while the user types would jump the cursor to the end.
        if view.text != text {
            view.text = text
        }
        if view.font != font {
            view.font = font
        }
        applyTextStyle(to: view)
        applyTextContainerInset(to: view)
        context.coordinator.textLimit = textLimit
        context.coordinator.scrollEnabledAfterLineCount = scrollEnabledAfterLineCount
        context.coordinator.configurePlaceholder(
            in: view,
            text: placeholder,
            lineSpacing: placeholderLineSpacing,
            font: placeholderFont,
            color: placeholderColor
        )
        context.coordinator.updatePlaceholderVisibility(in: view)
        scheduleScrollUpdate(for: view, coordinator: context.coordinator)
        updateFocus(of: view)
    }

    static func dismantleUIView(_ view: InstantTextView, coordinator: Coordinator) {
        view.cancelFocus()
        view.delegate = nil
    }

    private func scheduleScrollUpdate(for view: InstantTextView, coordinator: Coordinator) {
        DispatchQueue.main.async { [weak view] in
            guard let view else { return }
            coordinator.updateScrollGesture(in: view)
        }
    }

    private func updateFocus(of view: InstantTextView) {
        guard let shouldFocus = isFocused?.wrappedValue else { return }
        view.wantsFocus = shouldFocus
        guard view.window != nil, view.isFirstResponder != shouldFocus else { return }

        DispatchQueue.main.async { [weak view] in
            guard let view, view.wantsFocus == shouldFocus else { return }
            view.applyControlledFocus()
        }
    }

    private func applyTextContainerInset(to view: InstantTextView) {
        if let textContainerInset {
            view.textContainerInset = textContainerInset
            view.textContainer.lineFragmentPadding = 0
        } else {
            var inset = view.textContainerInset
            inset.top = Spacing.lg - 2
            inset.bottom = Spacing.lg - 2
            view.textContainerInset = inset
        }
    }

    private func applyTextStyle(to view: InstantTextView) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .kern: kerning
        ]

        var typingAttributes = view.typingAttributes
        typingAttributes.merge(attributes) { _, new in new }
        view.typingAttributes = typingAttributes

        guard view.textStorage.length > 0 else { return }
        view.textStorage.addAttributes(
            attributes,
            range: NSRange(location: 0, length: view.textStorage.length)
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            textLimit: textLimit,
            scrollEnabledAfterLineCount: scrollEnabledAfterLineCount
        )
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let text: Binding<String>
        var textLimit: Int
        var scrollEnabledAfterLineCount: Int?
        private var placeholderLabel: UILabel?

        init(text: Binding<String>, textLimit: Int, scrollEnabledAfterLineCount: Int?) {
            self.text = text
            self.textLimit = textLimit
            self.scrollEnabledAfterLineCount = scrollEnabledAfterLineCount
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            let currentText = textView.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(
                in: stringRange,
                with: replacement
            )
            let limit = max(0, textLimit)

            guard updatedText.count > limit else { return true }

            let limitedText = String(updatedText.prefix(limit))
            textView.text = limitedText
            text.wrappedValue = limitedText
            updatePlaceholderVisibility(in: textView)
            updateScrollGesture(in: textView)
            return false
        }

        func textViewDidChange(_ textView: UITextView) {
            let limitedText = String(textView.text.prefix(max(0, textLimit)))
            if textView.text != limitedText {
                textView.text = limitedText
            }
            text.wrappedValue = limitedText
            updatePlaceholderVisibility(in: textView)
            updateScrollGesture(in: textView)
        }

        func updateScrollGesture(in textView: UITextView) {
            guard let scrollEnabledAfterLineCount else {
                textView.panGestureRecognizer.isEnabled = true
                return
            }

            let shouldScroll = renderedLineCount(in: textView) > max(0, scrollEnabledAfterLineCount)
            let wasScrollEnabled = textView.panGestureRecognizer.isEnabled
            textView.panGestureRecognizer.isEnabled = shouldScroll

            if shouldScroll, !wasScrollEnabled {
                textView.scrollRangeToVisible(textView.selectedRange)
            } else if !shouldScroll {
                textView.setContentOffset(.zero, animated: false)
            }
        }

        private func renderedLineCount(in textView: UITextView) -> Int {
            let layoutManager = textView.layoutManager
            let glyphRange = layoutManager.glyphRange(for: textView.textContainer)
            guard glyphRange.length > 0 else { return 0 }

            var lineCount = 0
            layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, _, _ in
                lineCount += 1
            }

            // A trailing newline creates an empty line that has no glyph fragment.
            if textView.text.hasSuffix("\n") { lineCount += 1 }
            return lineCount
        }

        func configurePlaceholder(
            in textView: UITextView,
            text: String?,
            lineSpacing: CGFloat,
            font: UIFont,
            color: UIColor
        ) {
            guard let text, !text.isEmpty else {
                placeholderLabel?.removeFromSuperview()
                placeholderLabel = nil
                return
            }

            let label = placeholderLabel ?? UILabel()
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            label.attributedText = NSAttributedString(
                string: text,
                attributes: [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle
                ]
            )
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.isUserInteractionEnabled = false

            guard placeholderLabel == nil else { return }

            label.translatesAutoresizingMaskIntoConstraints = false
            textView.addSubview(label)

            let horizontalInset = textView.textContainerInset.left
                + textView.textContainerInset.right
                + textView.textContainer.lineFragmentPadding * 2

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(
                    equalTo: textView.topAnchor,
                    constant: textView.textContainerInset.top
                ),
                label.leadingAnchor.constraint(
                    equalTo: textView.leadingAnchor,
                    constant: textView.textContainerInset.left
                        + textView.textContainer.lineFragmentPadding
                ),
                label.widthAnchor.constraint(
                    equalTo: textView.widthAnchor,
                    constant: -horizontalInset
                )
            ])
            placeholderLabel = label
        }

        func updatePlaceholderVisibility(in textView: UITextView) {
            placeholderLabel?.isHidden = !textView.text.isEmpty
        }
    }
}

extension InstantKeyboardField {
    init(
        text: Binding<String?>,
        textLimit: Int = 130,
        placeholder: String? = nil,
        placeholderLineSpacing: CGFloat = 6,
        placeholderFont: UIFont = .body(18, .regular),
        placeholderColor: UIColor = .placeholderText,
        font: UIFont = .preferredFont(forTextStyle: .body),
        lineSpacing: CGFloat? = nil,
        kerning: CGFloat? = nil,
        scrollEnabledAfterLineCount: Int? = nil,
        textContainerInset: UIEdgeInsets? = nil,
        isFocused: Binding<Bool>? = nil
    ) {
        self.init(
            text: Binding(
                get: { text.wrappedValue ?? "" },
                set: { text.wrappedValue = $0 }
            ),
            textLimit: textLimit,
            placeholder: placeholder,
            placeholderLineSpacing: placeholderLineSpacing,
            placeholderFont: placeholderFont,
            placeholderColor: placeholderColor,
            font: font,
            textContainerInset: textContainerInset,
            isFocused: isFocused
        )
        if let lineSpacing { self.lineSpacing = lineSpacing }
        if let kerning { self.kerning = kerning }
        self.scrollEnabledAfterLineCount = scrollEnabledAfterLineCount
    }

    func font(_ font: UIFont) -> Self {
        var field = self
        field.font = font
        return field
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
