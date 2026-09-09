//
//  TimeBandGround.swift
//  Scoop
//
//  Created by Art Ostin on 08/09/2026.
//
//  The white ground the time platter lands on. The lens samples what sits behind it, so a platter that
//  overhangs the photo drinks the image and tints its own top edge. The fix is to carry the card's white
//  up over the photo's foot — but only as far as the platter actually reaches, and only as wide as it is.
//
//  A constant cannot do that. The platter is placed `.centred` on a label whose position moves with the
//  card's content (a message on the type row, the number of proposed times) while its own height moves
//  with its page, so the overlap runs from tens of points to none. A band taller than the overlap stands
//  proud of the platter as a bare bar on the photo; one shorter leaves the lens tasting the image.
//
//  Both rects arrive in GLOBAL coordinates: the menu draws in its own window whose overlay coords ARE
//  window coords (TimeCustomMenu), so the platter's placed frame and the pager's `.frame(in: .global)`
//  are directly comparable, and their overlap is the band.
//

import SwiftUI

@Observable
final class TimeBandGround {

    //Written every frame the card flies, and NEVER read while no platter is up — see the guard order in
    //`height`. That order is the dependency gate: read it unconditionally and every reader re-renders for
    //the life of the screen.
    private(set) var photoFrame: CGRect = .zero

    //`.zero` whenever no platter is up: the menu reports its placed frame, the card clears it on close
    private(set) var platterFrame: CGRect = .zero

    func reportPhoto(_ rect: CGRect) {
        guard rect != photoFrame else { return } //a same-value @Observable write stalls the lens's compositing
        photoFrame = rect
    }

    //Reported from inside the menu's own resize transaction, so a mid-open reflow moves the band on the
    //very spring the platter moves on — the two can never drift apart mid-flight
    func reportPlatter(_ rect: CGRect) {
        guard rect != platterFrame else { return }
        platterFrame = rect
    }

    func clear() {
        guard platterFrame != .zero else { return }
        platterFrame = .zero
    }

    //Geometry: how far the platter's top edge reaches up into the photo — the band's whole height
    var height: CGFloat {
        guard platterFrame.height > 0, photoFrame.height > 0 else { return 0 }
        return (photoFrame.maxY - platterFrame.minY).clamped(to: 0...photoFrame.height)
    }

    //Geometry: where the platter's centre sits against the photo's. The band wears the platter's own width
    //and rides to its centre rather than assuming both are centred on the same thing — the platter centres
    //on the safe band, the card on its own inset.
    var offsetX: CGFloat {
        guard platterFrame.width > 0, photoFrame.width > 0 else { return 0 }
        return platterFrame.midX - photoFrame.midX
    }
}

//The band itself, and a leaf on purpose: the menu reports a new frame on every frame of a reflow, and a
//read any higher would re-run the card's container — and with it TimeCustomMenu's body, whose live-label
//push defers a write into the observed controller once per pass.
struct TimeBandFill: View {

    static let bandFillDelay: TimeInterval = 0.04

    let ground: TimeBandGround?
    let visible: Bool

    var body: some View {
        Color.white //the card's own white, carried up over the photo's foot — not appCanvas, which cast warm
            .frame(width: ground?.platterFrame.width, height: ground?.platterFrame.height)
            .clipShape(RoundedRectangle(cornerRadius: TimeCustomMenuSpec.platterCornerRadius)) //the menu's own, so the two can never drift
            .frame(height: ground?.height ?? 0, alignment: .top) //top-anchored: the crop keeps the platter's TOP edge, corners and all
            .clipped()
            .offset(x: ground?.offsetX ?? 0)
            .opacity(visible ? 1 : 0)
            //Fades IN behind the platter, but CUTS out: the band must be gone before the platter
            //uncovers it, so its exit can never be a curve with a tail.
            .animation(visible ? .transition.delay(Self.bandFillDelay) : nil, value: visible)
    }
}
