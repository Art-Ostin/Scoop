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


@MainActor
@Observable
final class ResponseCoverPresenter {

    //The cover on screen. Driven through show/close, never assigned directly.
    private(set) var response: ProfileResponse?

    //Identifies the presentation on screen. Not observed — nothing renders from it.
    @ObservationIgnored private var presentation = 0

    //Fades a cover in, returning the handle its own flow must present to close it
    @discardableResult
    func show(_ response: ProfileResponse) -> Int {
        presentation += 1
        self.response = response
        return presentation
    }

    //Respond flows overlap: decline a second profile inside the first's minimum display
    //time and the first flow's trailing close would wipe the second's cover mid-display.
    //A stale handle closes nothing.
    func close(_ handle: Int?) {
        guard handle == presentation else { return }
        response = nil
    }
}

struct ResponseCoverLayer: View {
    var presenter: ResponseCoverPresenter
    var body: some View {
        ZStack {
            if let response = presenter.response {
                RespondedToProfileCover(responseType: response)
                    .transition(.opacity.animation(.transition))
            }
        }
        .ignoresSafeArea()
    }
}




struct RespondedToProfileCover: View {
    let responseType: ProfileResponse

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.xl) {
            switch responseType {
            case .accepted:
                AcceptInviteCard()
            case .newTime:
               AcceptInviteCard()
            case .newInvite:
                AcceptInviteCard()
            case .decline:
                DeclineOverlay()
            }
        }
        .colorBackground()
    }
}
