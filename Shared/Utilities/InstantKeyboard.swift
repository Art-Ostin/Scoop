//
//  InstantKeyboard.swift
//  Scoop Test
//
//  Created by Art Ostin on 20/07/2026.
//

import SwiftUI
import UIKit


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

Step 3: In a sheet with a keyboard-safe bottom button, opt into interactive
sheet overlap handling:

 CustomTextField(...)
     .sheetKeyboardOverlapTarget()

 content
     .sheetKeyboardOverlap(
         isFocused: $isFocused,
         isDismissing: $isDismissing
     ) {
         bottomButton
     }
 */

enum InstantKeyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// Prevents an overlap observer from restoring focus while its sheet closes,
    /// then dismisses the current first responder immediately.
    static func dismiss(
        isFocused: Binding<Bool>,
        isDismissing: Binding<Bool>
    ) {
        isDismissing.wrappedValue = true
        isFocused.wrappedValue = false
        dismiss()
    }
}

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
        InstantKeyboard.dismiss()
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

// MARK: - Interactive sheet keyboard overlap

private struct SheetKeyboardOverlapAnchors {
    var target: Anchor<CGRect>?
    var bottomBar: Anchor<CGRect>?
}

private struct SheetKeyboardOverlapAnchorsKey: PreferenceKey {
    static var defaultValue = SheetKeyboardOverlapAnchors()

    static func reduce(
        value: inout SheetKeyboardOverlapAnchors,
        nextValue: () -> SheetKeyboardOverlapAnchors
    ) {
        let nextValue = nextValue()
        value.target = nextValue.target ?? value.target
        value.bottomBar = nextValue.bottomBar ?? value.bottomBar
    }
}

extension View {
    /// Marks the field whose bottom edge must stay above the sheet's bottom bar.
    func sheetKeyboardOverlapTarget() -> some View {
        anchorPreference(
            key: SheetKeyboardOverlapAnchorsKey.self,
            value: .bounds
        ) { anchor in
            SheetKeyboardOverlapAnchors(target: anchor)
        }
    }

    /// Dismisses the keyboard if an interactive sheet drag would move the
    /// bottom bar over the marked target, then restores it if the drag reverses.
    /// Mark one descendant with `sheetKeyboardOverlapTarget()` first. The top
    /// edge of `bottomBar` is the collision boundary.
    ///
    /// `isFocused` must be the same `Binding<Bool>` passed to the actual input.
    /// Reset `isDismissing` to `false` when presenting, and call
    /// `InstantKeyboard.dismiss(isFocused:isDismissing:)` before closing.
    func sheetKeyboardOverlap<BottomBar: View>(
        isFocused: Binding<Bool>,
        isDismissing: Binding<Bool>,
        @ViewBuilder bottomBar: () -> BottomBar
    ) -> some View {
        safeAreaInset(edge: .bottom) {
            bottomBar()
                .anchorPreference(
                    key: SheetKeyboardOverlapAnchorsKey.self,
                    value: .bounds
                ) { anchor in
                    SheetKeyboardOverlapAnchors(bottomBar: anchor)
                }
        }
        .overlayPreferenceValue(SheetKeyboardOverlapAnchorsKey.self) { anchors in
            GeometryReader { geometry in
                if let target = anchors.target,
                   let bottomBar = anchors.bottomBar {
                    SheetKeyboardOverlapObserver(
                        textFieldBottom: geometry[target].maxY,
                        buttonTop: geometry[bottomBar].minY,
                        isFocused: isFocused,
                        isDismissing: isDismissing
                    )
                    .frame(width: 1, height: 1)
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct SheetKeyboardOverlapObserver: UIViewRepresentable {

    let textFieldBottom: CGFloat
    let buttonTop: CGFloat
    @Binding var isFocused: Bool
    @Binding var isDismissing: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            textFieldBottom: textFieldBottom,
            buttonTop: buttonTop,
            isFocused: $isFocused,
            isDismissing: $isDismissing
        )
    }

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.onMoveToWindow = { [weak coordinator = context.coordinator] view in
            coordinator?.attach(to: view)
        }
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: ProbeView, context: Context) {
        context.coordinator.update(
            textFieldBottom: textFieldBottom,
            buttonTop: buttonTop,
            isFocused: $isFocused,
            isDismissing: $isDismissing
        )
        context.coordinator.attach(to: view)
    }

    static func dismantleUIView(_ view: ProbeView, coordinator: Coordinator) {
        coordinator.tearDown()
    }

    final class ProbeView: UIView {
        var onMoveToWindow: ((ProbeView) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            onMoveToWindow?(self)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        private struct Reference {
            let contactOffset: CGFloat
            let anchorY: CGFloat
        }

        private static let dismissalHysteresis: CGFloat = 2

        private var textFieldBottom: CGFloat
        private var buttonTop: CGFloat
        private var isFocused: Binding<Bool>
        private var isDismissing: Binding<Bool>
        private weak var probe: ProbeView?
        private var observingPan: UIPanGestureRecognizer?
        private var displayLink: CADisplayLink?
        private var reference: Reference?
        private var lastAnchorY: CGFloat?
        private var stableFrames = 0
        private var restoreConfirmationFrames = 0
        private var panIsActive = false
        private var hiddenByDrag = false
        private var isTornDown = false

        init(
            textFieldBottom: CGFloat,
            buttonTop: CGFloat,
            isFocused: Binding<Bool>,
            isDismissing: Binding<Bool>
        ) {
            self.textFieldBottom = textFieldBottom
            self.buttonTop = buttonTop
            self.isFocused = isFocused
            self.isDismissing = isDismissing
            super.init()
        }

        deinit {
            displayLink?.invalidate()
        }

        func update(
            textFieldBottom: CGFloat,
            buttonTop: CGFloat,
            isFocused: Binding<Bool>,
            isDismissing: Binding<Bool>
        ) {
            self.textFieldBottom = textFieldBottom
            self.buttonTop = buttonTop
            self.isFocused = isFocused
            self.isDismissing = isDismissing

            if displayLink == nil,
               isFocused.wrappedValue,
               !hiddenByDrag,
               let reference {
                let restingAnchorY = currentAnchorY() ?? reference.anchorY
                if let updatedReference = makeReference(anchorY: restingAnchorY) {
                    self.reference = updatedReference
                }
            }

            if isDismissing.wrappedValue {
                hiddenByDrag = false
                restoreConfirmationFrames = 0
                stopDisplayLink()
            } else if reference == nil {
                startDisplayLink()
            }
        }

        func attach(to probe: ProbeView) {
            self.probe = probe
            guard !isTornDown, let window = probe.window else { return }

            installPanIfNeeded(on: window)
            if reference == nil {
                startDisplayLink()
            }
        }

        func tearDown() {
            isTornDown = true
            restoreConfirmationFrames = 0
            stopDisplayLink()
            if let observingPan {
                observingPan.view?.removeGestureRecognizer(observingPan)
            }
            observingPan = nil
            probe?.onMoveToWindow = nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        @objc private func windowPanned(_ pan: UIPanGestureRecognizer) {
            switch pan.state {
            case .began:
                panIsActive = true
                restoreConfirmationFrames = 0
                prepareReferenceForNewDrag()
                startDisplayLink()
            case .changed:
                panIsActive = true
                startDisplayLink()
            case .ended, .cancelled, .failed:
                panIsActive = false
                startDisplayLink()
            default:
                break
            }
        }

        @objc private func updateForSheetPosition() {
            guard !isDismissing.wrappedValue else {
                hiddenByDrag = false
                restoreConfirmationFrames = 0
                stopDisplayLink()
                return
            }
            guard let anchorY = currentAnchorY() else {
                stopDisplayLink()
                return
            }

            if reference == nil {
                captureReferenceIfStable(at: anchorY)
                return
            }
            guard let reference else { return }

            let sheetOffset = anchorY - reference.anchorY

            if isFocused.wrappedValue,
               sheetOffset > reference.contactOffset + Self.dismissalHysteresis {
                hiddenByDrag = true
                restoreConfirmationFrames = 0
                isFocused.wrappedValue = false
                probe?.window?.endEditing(true)
            } else if hiddenByDrag, sheetOffset <= reference.contactOffset {
                restoreConfirmationFrames += 1
                if (panIsActive || restoreConfirmationFrames >= 3),
                   !isTornDown,
                   !isDismissing.wrappedValue,
                   probe?.window != nil {
                    restoreConfirmationFrames = 0
                    hiddenByDrag = false
                    isFocused.wrappedValue = true
                }
            } else if hiddenByDrag {
                restoreConfirmationFrames = 0
            }

            if !panIsActive, abs(sheetOffset) < 0.25, !hiddenByDrag {
                if let updatedReference = makeReference(anchorY: anchorY) {
                    self.reference = updatedReference
                }
                stopDisplayLink()
            }
        }

        private func captureReferenceIfStable(at anchorY: CGFloat) {
            guard !panIsActive,
                  isFocused.wrappedValue,
                  let newReference = makeReference(anchorY: anchorY) else { return }

            if let lastAnchorY, abs(anchorY - lastAnchorY) < 0.1 {
                stableFrames += 1
            } else {
                stableFrames = 0
            }
            lastAnchorY = anchorY
            guard stableFrames >= 3 else { return }

            reference = newReference
            stableFrames = 0
            stopDisplayLink()
        }

        private func prepareReferenceForNewDrag() {
            guard isFocused.wrappedValue,
                  !hiddenByDrag else { return }
            let restingAnchorY = reference?.anchorY ?? currentAnchorY()
            guard let restingAnchorY,
                  let newReference = makeReference(anchorY: restingAnchorY) else { return }

            reference = newReference
        }

        private var currentContactOffset: CGFloat? {
            guard textFieldBottom > 0, buttonTop > 0 else { return nil }
            return max(buttonTop - textFieldBottom, 0)
        }

        private func makeReference(anchorY: CGFloat) -> Reference? {
            guard let contactOffset = currentContactOffset else { return nil }
            return Reference(
                contactOffset: contactOffset,
                anchorY: anchorY
            )
        }

        private func currentAnchorY() -> CGFloat? {
            guard let probe, let window = probe.window else { return nil }

            if let source = probe.layer.presentation(),
               let destination = window.layer.presentation() {
                return source.convert(source.bounds, to: destination).minY
            }
            return probe.layer.convert(probe.layer.bounds, to: window.layer).minY
        }

        private func installPanIfNeeded(on window: UIWindow) {
            guard observingPan?.view !== window else { return }
            if let observingPan {
                observingPan.view?.removeGestureRecognizer(observingPan)
            }

            let pan = UIPanGestureRecognizer(target: self, action: #selector(windowPanned))
            pan.maximumNumberOfTouches = 1
            pan.cancelsTouchesInView = false
            pan.delaysTouchesBegan = false
            pan.delaysTouchesEnded = false
            pan.delegate = self
            window.addGestureRecognizer(pan)
            observingPan = pan
        }

        private func startDisplayLink() {
            guard !isTornDown, displayLink == nil else { return }
            let displayLink = CADisplayLink(
                target: self,
                selector: #selector(updateForSheetPosition)
            )
            displayLink.add(to: .main, forMode: .common)
            self.displayLink = displayLink
            updateForSheetPosition()
        }

        private func stopDisplayLink() {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
}
