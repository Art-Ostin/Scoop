//
//  CustomAlert.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.

import SwiftUI

struct CustomAlertCard: ViewModifier {
    
    @Binding var isPresented: Bool
    
    //The Text
    let title: String
    var emoji: String
    let message: String
    
    //The Buttons
    let cancelTitle: String
    let okTitle: String
    let offset: CGFloat
    
    //What the buttons did
    let onOK: () -> Void
    let onCancel: (() -> ())?
    
    func body(content: Content) -> some View {
        ZStack {
            //The view which I have attached the modifier to, appears below
            content
            if isPresented {
                AlertPlate(alert: alert) { isPresented = false }
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .animation(AlertMotion.fade, value: isPresented)
    }

    //Rebuilt every pass, so an interpolated title or message tracks the latest body
    var alert: AlertRequest {
        AlertRequest(title: title, emoji: emoji, message: message,
                     cancelTitle: cancelTitle, okTitle: okTitle, offset: offset,
                     onOK: onOK, onCancel: onCancel)
    }
}

//The system alert's own fade, measured. Named rather than inlined because the plate now has two
//call sites — the in-place modifier and `AlertLayer` — and an alert must not animate differently
//depending on which plane it took. A measured replication, never a motion role.
enum AlertMotion {
    static let fade = Animation.easeInOut(duration: 0.18)
}

//Everything one alert says and does, so the plate can be drawn on a plane the call site cannot reach
struct AlertRequest {

    //The Text
    let title: String
    let emoji: String
    let message: String

    //The Buttons
    let cancelTitle: String
    let okTitle: String
    let offset: CGFloat

    //What the buttons did
    let onOK: () -> Void
    let onCancel: (() -> ())?
}

//The scrim and the card — the alert's whole appearance, in one place so the in-place route and a
//plane route can never draw different pixels
struct AlertPlate: View {

    //Injected
    let alert: AlertRequest
    let onBackdropTap: () -> Void

    var body: some View {
        ZStack {
            //A black cover filling the screen and above the content beneath
            Color.black.opacity(0.42).ignoresSafeArea()
                .onTapGesture { onBackdropTap() }

            //The Alert Card appearing above these two elements
            alertCard
                .offset(y: alert.offset) //Screens with the keyboard need the text higher
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

 extension AlertPlate {

     private var title: String { alert.title }
     private var emoji: String { alert.emoji }
     private var message: String { alert.message }
     private var cancelTitle: String { alert.cancelTitle }
     private var okTitle: String { alert.okTitle }
     private var onOK: () -> Void { alert.onOK }
     private var onCancel: (() -> ())? { alert.onCancel }

     private var alertCard: some View {
         VStack(alignment: .leading, spacing: 32) {
             titleAndMessage
             buttonSection
         }
         .modifier(AlertCardBackground())
     }
     
     private var titleAndMessage: some View {
         VStack(spacing: 24) {
             Text("\(title)  \(emoji)")
                 .font(.title(24, .bold))
                 .foregroundStyle(Color.textPrimary)


             Text(message)
                 .font(.body(16, .regular))
                 .foregroundStyle(Color.textPrimary)
                 .multilineTextAlignment(.center)
                 .lineSpacing(6)
         }
         .frame(maxWidth: .infinity, alignment: .center)
     }
     
     private var buttonSection: some View {
         VStack(spacing: 20) {
             okButton
             if let dismiss = onCancel { cancelButton(dismiss)}
         }
     }
     
     private var okButton: some View {
         ScoopButton(style: .tinted(.black, shadow: nil), shape: .capsule, press: .shrink) {
             onOK()
         } label: {
             Text(okTitle)
                 .font(.body(16, .bold))
                 .foregroundStyle(Color.white)
                 .frame(height: 50)
                 .frame(maxWidth: .infinity)
         }
     }
     
     private func cancelButton(_ action: @escaping () -> Void) -> some View {
         ScoopButton(style: .tinted(.clear, shadow: nil, glass: false), shape: .capsule, press: .shrink) {
             action()
         } label: {
             Text(cancelTitle)
                 .font(.body(16, .bold))
                 .foregroundStyle(Color.black)
                 .frame(height: 50)
                 .frame(maxWidth: .infinity)
                 .capsuleStroke(lineWidth: 1, color: .textTertiary)
         }
     }
 }

struct AlertCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
            .glassEffectIfAvailable(shape: RoundedRectangle(cornerRadius: CornerRadius.alert))
            .padding(.horizontal, 32)
            .shadow(.floating)
    }
}

extension View {
    func customAlertCard(
        isPresented: Binding<Bool>,
        
        title: String,
        emoji: String = "🦥",
        message: String,
        
        cancelTitle: String = "Cancel",
        okTitle: String = "OK",
        
        offset: CGFloat = 0,
        
        onOK: @escaping () -> Void,
        onCancel: (() -> ())? = nil
    ) -> some View {
        modifier(
            CustomAlertCard(
                isPresented: isPresented,
                title: title,
                emoji: emoji,
                message: message,
                cancelTitle: cancelTitle,
                okTitle: okTitle,
                offset: offset,
                onOK: onOK,
                onCancel: onCancel
            )
        )
    }
}

//MARK: - The plane

///The plane an alert renders on when the view raising it cannot reach the screen itself — an
///`.eventZoom` card body is masked by the morph's window, so a `.customAlertCard` inside one can
///only ever dim the card. A plane root owns this, mounts `AlertLayer` beside its content and hands
///it down; `.eventZoomAlert` is the one route into it today. Mount it per plane, never once at the
///app root: an alert raised inside a sheet or a cover must render on THAT plane, or it lands behind
///the presentation that raised it.
@MainActor @Observable final class AlertHost {

    ///The alert on screen, identified by the modifier that raised it — a second modifier's alert
    ///evicts the first rather than stacking behind it
    struct Slot: Identifiable {
        let id: UUID
        let alert: AlertRequest
        let dismiss: () -> Void //Writes the raiser's binding false; the slot clears through its `close`
    }

    private(set) var slot: Slot?

    ///Taken when the raiser's binding goes true. What it captures is what the alert says and does for
    ///as long as it is up — the text of an alert on screen must not track edits behind it.
    func present(id: UUID, alert: AlertRequest, dismiss: @escaping () -> Void) {
        slot = Slot(id: id, alert: alert, dismiss: dismiss)
    }

    ///A no-op unless this modifier is the one on screen, so a stale close never steals a live alert
    func close(id: UUID) {
        guard slot?.id == id else { return }
        slot = nil
    }
}

///The plane's alert, mounted the moment a slot is filled. Mount it above everything the plane draws
///— the card, its backdrop and its chrome — and outside any gesture the plane runs underneath.
struct AlertLayer: View {

    //Injected
    let host: AlertHost

    var body: some View {
        ZStack {
            if let slot = host.slot {
                //The backdrop writes the raiser's binding, exactly as the in-place route does: the plate
                //never clears the slot itself, or the binding would stay true and the alert never raise again
                AlertPlate(alert: slot.alert, onBackdropTap: slot.dismiss)
                    .transition(.opacity)
            }
        }
        .animation(AlertMotion.fade, value: host.slot?.id)
    }
}
