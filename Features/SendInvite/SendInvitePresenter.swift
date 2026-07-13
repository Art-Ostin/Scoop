//
//  SendInvitePresenter.swift
//  Scoop
//
//  Created by Art Ostin on 13/07/2026.
//

import SwiftUI


@Observable
final class SendInvitePresenter {

    //Card presentation state
    private(set) var pending: PendingProfile?
    private(set) var image: UIImage?
    private(set) var source: CGRect = .zero     //Frozen source frame of the flight in progress
    var expanded = false
    var dismissProgress: Double = 0

        
    @ObservationIgnored private var sourceRects: [String: CGRect] = [:]

    var presentedID: String? { pending?.id }
    func isPresenting(_ profileID: String) -> Bool { pending?.id == profileID }

    func reportSource(id: String, rect: CGRect) { sourceRects[id] = rect }

    func open(_ profile: PendingProfile, image: UIImage) {
        if pending?.id == profile.id {
            withAnimation(SendInviteCard.openFlight) { expanded = true }
            return
        }
        guard pending == nil else { return }
        dismissProgress = 0
        source = sourceRects[profile.id] ?? .zero            //Freeze the tapped card's frame for this flight
        self.image = image
        pending = profile
    }

    func close() {
        guard expanded else { return }
        //.logicallyComplete: tear down at the visual landing, not the spring's settling tail (the tail froze the collapsed card before the reveal)
        withAnimation(SendInviteCard.closeFlight, completionCriteria: .logicallyComplete) {
            expanded = false
        } completion: { [weak self] in
            guard let self, !expanded else { return }        //A reopen mid-close owns the card now
            clear()
        }
    }

    func reset() {
        expanded = false
        clear()
    }

    private func clear() {
        pending = nil
        image = nil
        source = .zero
    }
}

@MainActor
@Observable
final class InviteOverlayPresenter {

    struct Slot {
        let id: String
        let view: () -> AnyView
    }

    private(set) var invite: Slot?

    func show(id: String, view: @escaping () -> AnyView) {
        invite = Slot(id: id, view: view)
    }

    //Id-guarded so a stale clear can't drop a newer card.
    func clear(id: String) {
        if invite?.id == id { invite = nil }
    }
}

struct InviteOverlayLayer: View {
    var presenter: InviteOverlayPresenter

    var body: some View {
        if let i = presenter.invite { i.view().id(i.id) }
    }
}

private struct InviteOverlayModifier<Overlay: View>: ViewModifier {
    @Environment(InviteOverlayPresenter.self) private var presenter: InviteOverlayPresenter?
    let presentedID: String?
    @ViewBuilder let overlay: () -> Overlay

    func body(content: Content) -> some View {
        content
            .onChange(of: presentedID, initial: true) { oldID, newID in
                guard let presenter else { return }
                if let newID {
                    presenter.show(id: newID) { AnyView(overlay()) }
                } else if let oldID {
                    presenter.clear(id: oldID)
                }
            }
            .onDisappear {
                if let presentedID { presenter?.clear(id: presentedID) }
            }
    }
}

extension View {

    func inviteView(presentedID: String?, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(InviteOverlayModifier(presentedID: presentedID, overlay: content))
    }
}

struct SendInviteSourceModifier: ViewModifier {
    
    @Environment(SendInvitePresenter.self) private var presenter: SendInvitePresenter?
    let id: String

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rect in
            presenter?.reportSource(id: id, rect: rect)
        }
    }
}

extension View {
    func sendInviteSource(id: String) -> some View {
        modifier(SendInviteSourceModifier(id: id))
    }
}



@MainActor
struct SendInviteOverlay: View {
    
    @Bindable var presenter: SendInvitePresenter
    @State var vm: TimeAndPlaceViewModel
    let image: UIImage
    let images: [UIImage]
    let details: String
    let sendInvite: (EventFieldsDraft) -> Void
    var showsCollapsedChrome: Bool = true //Off when the flight grows from a plain image (profile hero) rather than a ProfileCard.

    var body: some View {
        ZStack {
            Color.appCanvas.ignoresSafeArea()
                .opacity(presenter.expanded ? 1 - presenter.dismissProgress : 0)
                //The backdrop fades on its own value-keyed scope so the close reveal LEADS the
                //card collapse. Keyed on `expanded` (not dismissProgress): an active drag still
                //scrubs the screen behind in 1:1, but a close fades the white out over .dismiss
                //(0.22s) — fully transparent before clear() unmounts the overlay at closeFlight's
                //.logicallyComplete (0.28s), so the tab behind shows through the collapse instead
                //of snapping in at teardown. Open keeps the flight curve.
                .animation(presenter.expanded ? SendInviteCard.openFlight : .dismiss,
                           value: presenter.expanded)
                .allowsHitTesting(presenter.expanded)
            SendInviteCard(
                vm: vm,
                image: image,
                images: images,
                details: details,
                expanded: $presenter.expanded,
                sourceFrame: presenter.source,
                onDismissProgress: { presenter.dismissProgress = $0 },
                hideInvite: { presenter.close() },
                sendInvite: sendInvite,
                showsCollapsedChrome: showsCollapsedChrome
            )
        }
    }
}

