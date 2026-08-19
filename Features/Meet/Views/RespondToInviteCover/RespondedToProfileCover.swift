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
 first out), the card follows on one quick beat — still rising on the axis it arrived on, so
 the dismissal reads as the same physical event ending. A reversed entrance would read as
 *undo*, which is the wrong meaning here. The backdrop it sat on is not this enum's business:
 `blurCover` clears the wash and resolves the blur on its own trailing clock.

 Staged like `Entrance` in AcceptInviteOverlay, so the curves live with the choreography
 instead of becoming three one-off roles.
 */
enum ResponseCoverExit {
    static let title = Animation.smooth(duration: 0.10)
    static let card = Animation.smooth(duration: 0.25)
    static let endScale: CGFloat = 0.94
    static let riseTravel: CGFloat = -Spacing.lg


    //The plane is torn down only once the last leg has finished — the longest exit any cover
    //runs is the accept card's 0.25s beat (the decline cross pops in 0.16s)
    static let duration: Duration = .milliseconds(320)
}


/*
 The reveal beat for a cover's title: the word fades up while rising into place. The accept
 card fires it from the transaction that flips `landed` (never from an `.animation(value:)`
 modifier, which would override the curve); the decline cross replays the same shape on its
 own keyframe clock — when its caption is switched on — so the reveal lands on the first impact.
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

    //What the send cover's hero flight lifts off with — the card image the tap handed over,
    //when the flow had one to measure. Read by the cover's SendInviteScreen.
    private(set) var sendFlight: SendInviteFlightSource?

    //Whether the app behind should be blurred and washed out. Drops at the *start* of the
    //close so the backdrop clears while the card is still leaving, rather than after it.
    var backdropEngaged: Bool { response != nil && !isClosing }

    //Fades a cover in, returning the handle its own flow must present to close it
    @discardableResult
    func show(_ response: ProfileResponse, from declineSource: CGRect? = nil,
              sendFlight: SendInviteFlightSource? = nil) -> Int {
        presentation += 1
        isClosing = false
        self.declineSource = declineSource
        self.sendFlight = sendFlight
        self.response = response
        return presentation
    }

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

    //The insertion choice must know whether the flight will actually run: SendInviteScreen
    //sits the flight out under Reduce Motion, and a .identity mount there would hard-cut the
    //resting circle over the still-sharp app instead of the flightless crossfade.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let response = presenter.response {
                RespondedToProfileCover(responseType: response, closing: presenter.isClosing,
                                        declineSource: presenter.declineSource, sendFlight: presenter.sendFlight)
            }
        }
        .ignoresSafeArea()
        //A cover that launches from something on screen (the decline cross, the send flight's
        //card image) mounts with .identity — a plane fade over the flying copy would double-dip
        //its opacity mid-travel. Covers with nothing to hand off from keep the fade.
        .transition(.asymmetric(
            insertion: presenter.response == .decline || (presenter.sendFlight != nil && !reduceMotion)
                ? .identity : .opacity.animation(.transition),
            removal: .identity))
    }
}


struct RespondedToProfileCover: View {

    //Injected
    let responseType: ProfileResponse
    var closing = false
    var declineSource: CGRect? = nil
    var sendFlight: SendInviteFlightSource? = nil

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.xl) {
            switch responseType {
            case .accepted:
                AcceptInviteCard(closing: closing)
            case .newTime:
                SendInviteScreen(flight: sendFlight, closing: closing)
            case .newInvite:
                SendInviteScreen(flight: sendFlight, closing: closing)
            case .decline:
                DeclineOverlay(closing: closing, source: declineSource)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //No canvas of its own: the blurred, washed-out app *is* the background now, painted
        //behind the whole plane by `blurCover` in AppContainer.
    }
}
