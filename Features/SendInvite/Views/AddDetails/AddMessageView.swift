//
//  InviteAddMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI
import UIKit

private enum AddMessageCoordinateSpace {
    static let sheet = "AddMessageSheet"
}

struct AddMessageView: View {
    
    //Injected
    @Environment(\.dismiss) private var dismiss
    @Binding var message: String?
    let isRespondMessage: Bool
    var name: String? = nil
    @Binding var eventType: Event.EventType

    //Local view state
    @State private var showSaved: Bool = false
    @State private var hasEditedThisSession: Bool = false
    @State private var keyPressToken = 0
    @State private var showTypePopup: Bool = false
    @State private var openTypes: Set<Event.EventType> = []
    @State private var messageFieldFocused = true
    @State private var isDismissing = false
    @State private var textFieldBottom: CGFloat = 0
    @State private var doneButtonTop: CGFloat = 0


    var body: some View {
        VStack(alignment: .leading, spacing: 56) {
            messageTitle
            VStack(spacing: 20) {
                typeDropdown
                CustomTextField(
                    text: $message,
                    isFocused: $messageFieldFocused,
                    placeHolder: eventType.textPlaceholder
                )
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .named(AddMessageCoordinateSpace.sheet)).maxY
                } action: { textFieldBottom = $0 }
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, Spacing.margin)
        .frame(maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .topTrailing) {savedOverlayIcon}
        .safeAreaInset(edge: .bottom) {doneButton}
        .coordinateSpace(name: AddMessageCoordinateSpace.sheet)
        .background(alignment: .topLeading) {
            SheetKeyboardOverlapObserver(
                textFieldBottom: textFieldBottom,
                buttonTop: doneButtonTop,
                isFocused: $messageFieldFocused,
                isDismissing: $isDismissing
            )
            .frame(width: 1, height: 1)
        }
        
        
        //All Logic dealing with SavedIcon
        .task(id: message) { await showSavedButton() }
        .onAppear {
            hasEditedThisSession = false
            showSaved = false
            messageFieldFocused = true
            isDismissing = false
        }
        .onChange(of: message) {
            hasEditedThisSession = true
            keyPressToken &+= 1
        }
        .onDisappear {
            isDismissing = true
            messageFieldFocused = false
            resignKeyboard()
        }
    }
}

extension AddMessageView {
    private var messageTitle: some View {
        Text("Add a Note")
            .font(.title(28))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var typeDropdown: some View {
        TimeCustomMenu(placementOffsetY: -60, isOpen: $showTypePopup) {
            SelectTypeView(
                openTypes: $openTypes,
                selectedType: $eventType, 
                showMessageScreen: .constant(false), message: ""
            )
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(eventType.longTitle).font(.body(17, .medium))
                DropDownButton(isOpen: showTypePopup)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, Spacing.xxs) //Looks better sligtly inset
    }
    
    private var savedOverlayIcon: some View {
        SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: false)
            .offset(y: -36)
            .padding(.horizontal, Spacing.margin)
            .opacityPop(visible: showSaved)
    }
    
    private var doneButton: some View {
        WideActionButton(text: "Done", isActive: true) {
            isDismissing = true
            messageFieldFocused = false
            resignKeyboard()
            dismiss()
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .named(AddMessageCoordinateSpace.sheet)).minY
        } action: { doneButtonTop = $0 }
        .padding(.bottom, Spacing.md)
        .padding(.horizontal, Spacing.margin)
    }
    
    private func showSavedButton() async {
        guard hasEditedThisSession else { return }
        if keyPressToken != 0 {
            withAnimation(.toggle) { showSaved = true }
            try? await Task.sleep(for: .seconds(1))
            withAnimation(.toggle) { showSaved = false}
        }
    }

    private func resignKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}


// The button initially stays pinned above the keyboard while the flexible gap
// above it collapses. Track both that gap and the sheet's presentation movement
// so focus changes only once the button itself starts moving down.
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




/*
 
 
 
 
 private var textFieldSection: some View {
     InstantKeyboardField(
         text: $message,
         textLimit: messageLimit,
         placeholder: eventType.textPlaceholder,
         font: .body(18)
     )
         .padding(.horizontal)
         .frame(maxWidth: .infinity)
         .frame(height: 145)
         .customScrollFade(height: Spacing.lg, color: .white, edge: .top)
         .customScrollFade(height: Spacing.lg, color: .white, edge: .bottom)
         .clipShape(.rect(cornerRadius: CornerRadius.xl))
         .stroke(CornerRadius.xl, color: Color.border)
         .overlay(alignment: .bottomTrailing) {countRemainingText}
 }

 
 @ViewBuilder
 private var countRemainingText: some View {
     let remaining = max(0, messageLimit - (message ?? "").count)
     if remaining <= warningThreshold {
         Text("\(remaining)")
             .font(.body(14))
             .foregroundStyle(Color.warningYellow)
             .padding(.trailing, Spacing.sm)
             .padding(.bottom, Spacing.sm)
     }
 }

 
 
 
 .padding(.horizontal, Spacing.margin)
 .frame(maxHeight: .infinity, alignment: .top)
 .ignoresSafeArea(.keyboard, edges: .bottom)

 */
