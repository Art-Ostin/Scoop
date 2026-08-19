//
//  SendInviteScreen.swift
//  Scoop
//
//  Created by Art Ostin on 19/08/2026.
//

import SwiftUI

/*
 The sent invite's cover: the card image the user just sent lifts off the invite popup and
 flies into the resting circle, one continuous surface the whole way — the same UIImage the
 confirm screen showed, morphing position, size and clip in a single spring while the
 BlurCover wash swallows the card it left behind. The glass ring and glow grow out beneath
 the descending image on that same spring, so image, ring and glow overshoot and settle as
 one body — a shared clock, never a flight followed by a reveal.

 The hand-off is seam-free by construction: on frame 1 the copy renders OPAQUE at the card
 image's measured global rect over pixel-identical artwork, so mounting it changes nothing
 on screen — and from that frame the wash blurring the card beneath can never touch the
 image, which stays crisp until it moves. (An earlier fade-in of the copy let the rising
 blur show through at partial opacity — the image visibly hazed then re-sharpened before
 lift-off; sim frames, 2026-08-19. Opaque-from-frame-1 is the no-flash guarantee.)
 */

//What the send button hands the cover to fly: captured at the tap, while the card is at rest.
struct SendInviteFlightSource {
    let image: UIImage //The page the user was looking at
    let frame: CGRect //Its resting global rect
    let cornerRadius: CGFloat //The card mask's clip radius, so the copy's corners match on frame 1
}

//Geometry-matched hero flight: its measured curves live in-file, per the motion rules.
enum SendFlightMotion {
    //THE tuning knob — the flight's clock, shared by EVERY moving part (image, ring, glow,
    //shadows), so the arrival reads as one movement rather than a flight plus a reveal.
    //Duration is the travel time; bounce is how hard everything dives through its resting
    //pose and springs back — the choreography's whole personality lives in these two numbers.
    static let spring = Spring(duration: 0.48, bounce: 0.42)
    static let flight = Animation.spring(spring)

    //One rendered frame so the source pose is committed — a flight fired inside the mount
    //transaction snaps to destination (the accept card's commitGuard, same trap).
    static let commitGuard: Duration = .milliseconds(30)
}

struct SendInviteScreen: View {

    //Injected
    var flight: SendInviteFlightSource? = nil
    var closing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    //Local view state
    @State private var arrived = false //The ONE flight flag: geometry, ring, glow and shadows all key on it
    @State private var hasFired = false

    static let imageSize: CGFloat = 225
    static let ringSize: CGFloat = 275

    //No measured source (the respond flows, previews) — or reduced motion — presents the
    //resting pose from the first frame, exactly as this screen behaved before the flight
    private var atRest: Bool { flight == nil || reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let rect = imageRect(in: geo)
            //The halo (glow + glass ring) RIDES the image: hidden inscribed behind it at the
            //source, growing out past its shrinking edges on the same spring, landing as the
            //resting 25pt annulus. Scale + position transforms only — a glass lens whose
            //FRAME animates re-renders every frame and tanks the device to ~15fps.
            let haloSettled = atRest || arrived
            let haloCenter = haloSettled ? center : CGPoint(x: rect.midX, y: rect.midY)
            let haloScale = haloSettled ? 1 : min(rect.width, rect.height) / Self.ringSize
            ZStack {
                Circle()
                    .fill(.accent.opacity(0.1))
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .blur(radius: 50)
                    .opacity(haloSettled ? 1 : 0)
                    .scaleEffect(haloScale)
                    .position(haloCenter)
                    .allowsHitTesting(false)

                Circle()
                    .fill(.clear)
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .glassEffectIfAvailable(shape: Circle())
                    .opacity(haloSettled ? 1 : 0)
                    .scaleEffect(haloScale)
                    .position(haloCenter)

                heroImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: rect.width, height: rect.height)
                    //Sanctioned .circular: a rounded rect standing in for a true circle — at
                    //rest the radius is half the frame, a pixel-exact Circle(); in flight it
                    //morphs continuously from the card's clip
                    .clipShape(.rect(cornerRadius: imageRadius, style: .circular))
                    .shadow(color: .black.opacity(haloSettled ? 0.25 : 0), radius: 2, x: 0, y: 0)
                    .shadow(color: .black.opacity(haloSettled ? 0.15 : 0), radius: 10, x: 0, y: 0)
                    .position(x: rect.midX, y: rect.midY)
            }
            //The covers' shared exit: still rising on the axis it arrived on (see ResponseCoverExit)
            .scaleEffect(closing ? ResponseCoverExit.endScale : 1)
            .offset(y: closing ? ResponseCoverExit.riseTravel : 0)
            .opacity(closing ? 0 : 1)
            .animation(ResponseCoverExit.card, value: closing)
        }
        .task { await enter() }
    }
}

//Flight geometry and choreography
extension SendInviteScreen {

    private var heroImage: Image {
        if let flight { Image(uiImage: flight.image) } else { Image("ProfileMockB") }
    }

    //The flight's two poses: the handed-over global rect, and the resting circle. Global →
    //local through the plane's own global origin (identity in practice — the cover plane is
    //full-bleed — but never assumed).
    private func imageRect(in geo: GeometryProxy) -> CGRect {
        let dest = CGRect(x: (geo.size.width - Self.imageSize) / 2,
                          y: (geo.size.height - Self.imageSize) / 2,
                          width: Self.imageSize, height: Self.imageSize)
        guard let flight, !atRest, !arrived else { return dest }
        let origin = geo.frame(in: .global).origin
        return flight.frame.offsetBy(dx: -origin.x, dy: -origin.y)
    }

    private var imageRadius: CGFloat {
        guard let flight, !atRest, !arrived else { return Self.imageSize / 2 }
        return flight.cornerRadius
    }

    /*
     One committed frame at the source pose (the copy is opaque from the mount — the seam is
     pixel identity, never a fade), then ONE transaction flips `arrived` and every moving
     part rides the same spring: the image's travel, size and clip, the ring and glow
     growing out beneath it, the shadows deepening. Shared clock, shared overshoot, shared
     settle — the arrival is one movement.
     */
    private func enter() async {
        guard flight != nil, !atRest, !hasFired else { return }
        hasFired = true
        try? await Task.sleep(for: SendFlightMotion.commitGuard)
        if Task.isCancelled { hasFired = false; return }

        withAnimation(SendFlightMotion.flight) { arrived = true }
    }
}

#Preview {
    SendInviteScreen()
}
