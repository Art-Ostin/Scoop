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


    //The plane is torn down only once the last leg has finished — the longest SHARED exit is
    //the accept card's 0.25s beat (the decline cross pops in 0.16s). An accept close that
    //flies holds longer, on AcceptFlightMotion's own clock.
    static let duration: Duration = .milliseconds(320)
}


//What an accepted invite hands the cover to land: captured at the tap, before the accept
//write drops the invites' image cache. The image doubles as the overlay's hero — the same
//first photo the event card's carousel opens on, so the hand-off is pixel identity.
struct AcceptFlightSource {
    let image: UIImage
    let eventId: String //The event whose card is the landing pad
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

    //Who the cover is about — the invitee's name the send cover's title announces.
    private(set) var inviteeName: String?

    //The accepted invite's landing flight — armed at show(), resolved at close(). While
    //armed, the event card it will land on hides its own image; `acceptFlightLanded` is the
    //hand-off that un-hides it beneath the still-opaque flown copy.
    private(set) var acceptFlight: AcceptFlightSource?

    //Resolved in the close() transaction itself, so the cover reads its landing rect in the
    //same update its `closing` flips. nil = the shared fade exit.
    private(set) var acceptFlightDestination: CGRect?

    //Flipped by the card's hand-off, in a no-animation transaction: the destination un-hides
    //while the copy still owns the pixels, never before.
    private(set) var acceptFlightLanded = false

    //Live global rects of candidate landing pads, reported by event cards while a flight is
    //armed — stamped, because silence since the last report is the settle signal close()
    //gates on. Not observed — nothing renders from them; close() reads once.
    @ObservationIgnored private var destinationFrames: [String: (rect: CGRect, at: Date)] = [:]

    //The cover plane's own global bounds, pushed by ResponseCoverLayer — the on-screen half
    //of close()'s landing-pad gate. .zero (never mounted) simply fails the gate.
    @ObservationIgnored var planeBounds: CGRect = .zero

    //Pushed in by ResponseCoverLayer (a presenter can't read the environment): a reduced-
    //motion close must fall back to the shared fade AND disarm, so the landing pad never
    //stays hidden for a flight that won't run.
    @ObservationIgnored var reduceMotion = false

    //Whether the app behind should be blurred and washed out. Drops at the *start* of the
    //close so the backdrop clears while the card is still leaving, rather than after it.
    var backdropEngaged: Bool { response != nil && !isClosing }

    //Fades a cover in, returning the handle its own flow must present to close it
    @discardableResult
    func show(_ response: ProfileResponse, from declineSource: CGRect? = nil,
              sendFlight: SendInviteFlightSource? = nil, inviteeName: String? = nil,
              acceptFlight: AcceptFlightSource? = nil) -> Int {
        presentation += 1
        isClosing = false
        self.declineSource = declineSource
        self.sendFlight = sendFlight
        self.inviteeName = inviteeName
        self.acceptFlight = response == .accepted ? acceptFlight : nil
        acceptFlightDestination = nil
        acceptFlightLanded = false
        destinationFrames.removeAll()
        self.response = response
        return presentation
    }

    func close(_ handle: Int?) {
        guard handle == presentation, !isClosing else { return }
        //Resolve the flight in the close transaction, so the card reads its landing rect in
        //the same update its `closing` flips. No LANDABLE pad (a failed write leaves no
        //card; a slow write leaves one still settling) or reduced motion falls back to the
        //shared fade — and disarms, un-hiding the pad.
        if let flight = acceptFlight, !reduceMotion,
           let pad = destinationFrames[flight.eventId], landable(pad) {
            acceptFlightDestination = pad.rect
        } else {
            acceptFlight = nil
        }
        isClosing = true
        let closing = presentation
        let hold: Duration = acceptFlightDestination == nil
            ? ResponseCoverExit.duration : AcceptFlightMotion.teardown
        Task {
            try? await Task.sleep(for: hold)
            guard closing == presentation else { return } //A newer cover arrived mid-exit and owns the plane now
            response = nil
            isClosing = false
            acceptFlight = nil
            acceptFlightDestination = nil
            acceptFlightLanded = false
            destinationFrames.removeAll()
        }
    }
}

//The accept flight's landing-pad protocol: the event card reports where landing would be and
//hides its own image while the flown copy owns the pixels.
extension ResponseCoverPresenter {

    //Called from the event card's geometry observer — live, so the rect close() reads is the
    //card's current resting frame, not a stale mount-time one.
    func reportEventImageFrame(_ frame: CGRect, id: String) {
        guard acceptFlight?.eventId == id else { return }
        destinationFrames[id] = (frame, Date())
    }

    //A landable pad: full-size (an image-less carousel collapses to a sliver), fully on
    //screen (an un-jumped pager page sits a full width right; a scrolled-away card is no
    //target), and at rest (a settling scroll re-reports every frame, so silence since the
    //last report IS the settle signal). Anything else forfeits the flight to the shared
    //fade — a fade is always right; a flight to a wrong rect never is.
    private func landable(_ pad: (rect: CGRect, at: Date)) -> Bool {
        pad.rect.width > 150 && pad.rect.height > 150
            && planeBounds.insetBy(dx: -2, dy: -2).contains(pad.rect)
            && Date().timeIntervalSince(pad.at) > 0.15
    }

    func eventImageHidden(_ id: String) -> Bool {
        acceptFlight?.eventId == id && !acceptFlightLanded
    }

    func acceptFlightDidLand() {
        acceptFlightLanded = true
    }

    //The window BlurCover keeps the plane (and its touch guard) mounted after this cover
    //disengages: a landing flight outlives the shared exit, so its close holds longer.
    var exitContentHold: Duration {
        acceptFlightDestination == nil ? BlurCoverMotion.contentHold : AcceptFlightMotion.contentHold
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
                                        declineSource: presenter.declineSource, sendFlight: presenter.sendFlight,
                                        inviteeName: presenter.inviteeName,
                                        acceptFlight: presenter.acceptFlight,
                                        acceptDestination: presenter.acceptFlightDestination,
                                        onAcceptLanded: { presenter.acceptFlightDidLand() })
            }
        }
        .ignoresSafeArea()
        .transition(.asymmetric(
            insertion: presenter.response == .decline || (presenter.sendFlight != nil && !reduceMotion)
                ? .identity : .opacity.animation(.transition),
            removal: .identity))
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { presenter.planeBounds = $0 }
        .onChange(of: reduceMotion, initial: true) { presenter.reduceMotion = $1 }
    }
}

struct RespondedToProfileCover: View {

    //Injected
    let responseType: ProfileResponse
    var closing = false
    var declineSource: CGRect? = nil
    var sendFlight: SendInviteFlightSource? = nil
    var inviteeName: String? = nil
    var acceptFlight: AcceptFlightSource? = nil
    var acceptDestination: CGRect? = nil
    var onAcceptLanded: () -> Void = {}

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.xl) {
            switch responseType {
            case .accepted:
                AcceptInviteCard(flight: acceptFlight, closing: closing, destination: acceptDestination,
                                 name: inviteeName, onFlightLanded: onAcceptLanded)
            case .newTime:
                SendInviteScreen(flight: sendFlight, closing: closing, name: inviteeName)
            case .newInvite:
                SendInviteScreen(flight: sendFlight, closing: closing, name: inviteeName)
            case .decline:
                DeclineOverlay(closing: closing, source: declineSource)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //No canvas of its own: the blurred, washed-out app *is* the background now, painted
        //behind the whole plane by `blurCover` in AppContainer.
    }
}
