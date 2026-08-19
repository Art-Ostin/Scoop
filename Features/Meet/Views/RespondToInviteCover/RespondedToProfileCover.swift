//
//  RespondedToProfileCover.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

enum ProfileResponse {
    case accepted
    case newTime
    case newInvite
    case decline
}


/*
 The exit: the moment lifts away rather than switching off. The title leaves first (last in,
 first out), the canvas and the card follow together on one quick beat — the card still rising
 on the axis it arrived on, so the dismissal reads as the same physical event ending. A
 reversed entrance would read as *undo*, which is the wrong meaning here.

 Staged like `Entrance` in AcceptInviteOverlay, so the curves live with the choreography
 instead of becoming three one-off roles.
 */
enum ResponseCoverExit {
    static let title = Animation.smooth(duration: 0.10)
    static let canvas = Animation.smooth(duration: 0.22)
    static let card = Animation.smooth(duration: 0.25)
    static let endScale: CGFloat = 0.94
    static let riseTravel: CGFloat = -Spacing.lg


    //The plane is torn down only once the last leg has finished
    static let duration: Duration = .milliseconds(260)
}


/*
 The reveal beat, shared by both covers' titles: the word fades up while rising into place.
 The accept card fires it from the transaction that flips `landed` (never from an
 `.animation(value:)` modifier, which would override the curve); the decline cross replays
 the same shape on its own keyframe clock so the reveal lands exactly on the first impact.
 */
enum ResponseCoverEntrance {
    static let titleReveal = Animation.spring(duration: 0.5, bounce: 0)
    static let titleRise = Spacing.sm
}


@MainActor
@Observable
final class ResponseCoverPresenter {

    //The cover on screen. Driven through show/close, never assigned directly.
    private(set) var response: ProfileResponse?

    //Drives the staged exit. The cover stays mounted through it — a removal transition tears
    //the subtree down, so the card's own state could never animate itself out.
    private(set) var isClosing = false

    //Identifies the presentation on screen. Not observed — nothing renders from it.
    @ObservationIgnored private var presentation = 0

    //Where the decline cross launches from — the decline button's global frame, when the
    //tap had one to measure. Read by the cover's DeclineOverlay.
    private(set) var declineSource: CGRect?

    //Fades a cover in, returning the handle its own flow must present to close it
    @discardableResult
    func show(_ response: ProfileResponse, from declineSource: CGRect? = nil) -> Int {
        presentation += 1
        isClosing = false
        self.declineSource = declineSource
        self.response = response
        return presentation
    }

    //Respond flows overlap: decline a second profile inside the first's minimum display
    //time and the first flow's trailing close would wipe the second's cover mid-display.
    //A stale handle closes nothing.
    func close(_ handle: Int?) {
        guard handle == presentation, !isClosing else { return }
        isClosing = true
        let closing = presentation
        Task {
            try? await Task.sleep(for: ResponseCoverExit.duration)
            guard closing == presentation else { return } //A newer cover arrived mid-exit and owns the plane now
            response = nil
            isClosing = false
        }
    }
}

struct ResponseCoverLayer: View {
    var presenter: ResponseCoverPresenter
    var body: some View {
        ZStack {
            if let response = presenter.response {
                RespondedToProfileCover(responseType: response, closing: presenter.isClosing, declineSource: presenter.declineSource)
                    //Insertion only: the staged exit has already taken every layer to zero by
                    //the time the branch is removed, so a removal transition would double-fade.
                    //Decline inserts whole — its cross must sit opaque on the button from the
                    //first frame, so the cover's canvas fades itself in beneath it instead.
                    .transition(.asymmetric(
                        insertion: response == .decline ? .identity : .opacity.animation(.transition),
                        removal: .identity))
            }
        }
        .ignoresSafeArea()
    }
}


struct RespondedToProfileCover: View {

    //Injected
    let responseType: ProfileResponse
    var closing = false
    var declineSource: CGRect? = nil

    //Local view state
    //Decline inserts with .identity so its cross starts opaque on the button — the canvas
    //fades in here instead of riding an insertion transition the cross would inherit.
    @State private var canvasEntered = false

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.xl) {
            switch responseType {
            case .accepted:
                AcceptInviteCard(closing: closing)
            case .newTime:
               AcceptInviteCard(closing: closing)
            case .newInvite:
                AcceptInviteCard(closing: closing)
            case .decline:
                //The cross carries its own choreography — it leaves whole, on the card's leg,
                //while its title leaves ahead of it on the title's own faster leg
                DeclineOverlay(closing: closing, source: declineSource)
                    .opacity(closing ? 0 : 1)
                    .animation(ResponseCoverExit.card, value: closing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //Its own opaque canvas, thinning on the exit's own leg alongside the card
        .background {
            Color.appCanvas
                .opacity(closing ? 0 : (canvasEntered ? 1 : 0))
                .animation(ResponseCoverExit.canvas, value: closing)
                .ignoresSafeArea()
        }
        .onAppear {
            //Non-decline covers fade in whole, so their canvas lands opaque with no beat of its own
            withAnimation(responseType == .decline ? .transition : nil) { canvasEntered = true }
        }
    }
}
