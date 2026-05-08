
/*
 
 //  ProfileSheetMirror.swift
 //  Scoop
 //
 //  The native iPhone sheet clips any content that extends beyond its bounds,
 //  so the visible card cannot be widened from inside the sheet. The pieces
 //  in this file work together to render a *parallel* card outside the sheet
 //  that mirrors the sheet's frame in real time:
 //
 //    - `ProfileDetailsView` calls `publishesSheetGeometry(to:)` so the live
 //      sheet frame (in global coords) flows into ProfileUIState.
 //    - `ProfileView` renders `ParallelDetailsCard` as an overlay on the
 //      parent (outside the sheet's clipping container) and reads those same
 //      ProfileUIState values to position itself.
 //
 //  Drag vs. snap is detected on the consumer side (the card) by the size of
 //  each frame delta: tiny per-frame deltas during a drag are applied
 //  instantly, while a single big delta on release triggers a spring. Doing
 //  this on the consumer side rather than inside `onGeometryChange`'s action
 //  matters because `withAnimation` inside that action does not reliably
 //  propagate to `@Observable` mutations on iOS 26.
 //
 //  Tuning the snap feel: edit `SheetSnapAnimation.value`.

 import SwiftUI

 // MARK: - Animation

 private enum SheetSnapAnimation {
     static let value: Animation = .spring(response: 0.32, dampingFraction: 0.92)
     /// Threshold for treating a frame delta as a "snap" (release flick to a
     /// new detent) rather than a per-frame drag update.
     static let snapDeltaThreshold: CGFloat = 60
 }

 // MARK: - Geometry publisher

 extension View {
     /// Apply to the root of the sheet's content. Publishes the live sheet
     /// frame (global coords) into `ProfileUIState` so the parallel card
     /// overlay outside the sheet can mirror it.
     func publishesSheetGeometry(to ui: ProfileUIState) -> some View {
         modifier(SheetGeometryPublisher(ui: ui))
     }
 }

 private struct SheetGeometryPublisher: ViewModifier {
     @Bindable var ui: ProfileUIState

     func body(content: Content) -> some View {
         content
             .onGeometryChange(for: CGRect.self) { proxy in
                 proxy.frame(in: .global)
             } action: { newFrame in
                 ui.sheetTopY = newFrame.minY
                 ui.sheetHeight = newFrame.height
             }
     }
 }

 // MARK: - Parallel card

 /// Visible card frame rendered outside the sheet's clipping container.
 /// Position and size mirror the sheet's frame; width and corner radius
 /// interpolate between the small and large detents using the live sheet
 /// height.
 struct ParallelDetailsCard: View {
     @Bindable var ui: ProfileUIState

     /// The size of the container view this overlay is placed in (typically
     /// the parent's GeometryProxy.size).
     let containerSize: CGSize

     /// The container's origin in global coordinates. Used to convert the
     /// sheet's globalY into the overlay's local coordinate space.
     let containerOriginY: CGFloat

     private let smallHorizontalInset: CGFloat = 16
     private let largeHorizontalInset: CGFloat = 0
     private let smallCorner: CGFloat = 28
     private let largeCorner: CGFloat = 20

     /// The values actually rendered by the card. We mirror `ui.sheetTopY` /
     /// `ui.sheetHeight` into local @State so we can apply `withAnimation`
     /// here (where it reliably catches the mutation), then drive the
     /// frame/offset off the local copies.
     @State private var displayTop: CGFloat = 0
     @State private var displayHeight: CGFloat = 0

     var body: some View {
         let progress = self.progress
         let horizontalInset = lerp(smallHorizontalInset, largeHorizontalInset, progress)
         let cornerRadius = lerp(smallCorner, largeCorner, progress)

         let cardTop = max(0, displayTop - containerOriginY)
         let cardWidth = max(0, containerSize.width - 2 * horizontalInset)

         UnevenRoundedRectangle(
             topLeadingRadius: cornerRadius,
             topTrailingRadius: cornerRadius
         )
         .fill(Color.background)
         .frame(width: cardWidth, height: displayHeight)
         .offset(x: horizontalInset, y: cardTop)
         // Native sheet sits above this view; gestures must reach it.
         .allowsHitTesting(false)
         .onAppear {
             displayTop = ui.sheetTopY
             displayHeight = ui.sheetHeight
         }
         .onChange(of: ui.sheetTopY) { oldValue, newValue in
             apply(newTop: newValue, newHeight: ui.sheetHeight, previousTop: oldValue)
         }
         .onChange(of: ui.sheetHeight) { _, newValue in
             // Height also changes during drag, but the top change usually
             // arrives in the same tick. Apply directly — animation already
             // covered by the top's onChange when needed.
             displayHeight = newValue
         }
     }

     private func apply(newTop: CGFloat, newHeight: CGFloat, previousTop: CGFloat) {
         let isSnap = abs(newTop - previousTop) > SheetSnapAnimation.snapDeltaThreshold
         if isSnap {
             withAnimation(SheetSnapAnimation.value) {
                 displayTop = newTop
                 displayHeight = newHeight
             }
         } else {
             displayTop = newTop
             displayHeight = newHeight
         }
     }

     private var progress: CGFloat {
         let minHeight = containerSize.height * ui.smallDetent
         let maxHeight = containerSize.height * ui.largeDetent
         guard maxHeight > minHeight else { return 0 }
         let raw = (displayHeight - minHeight) / (maxHeight - minHeight)
         return min(max(raw, 0), 1)
     }

     private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
         a + (b - a) * t
     }
 }

 */
