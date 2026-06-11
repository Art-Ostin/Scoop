//
//  ProfileGestures.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/05/2026.
//

import SwiftUI

//How a drag is resolved once the finger moves past the slop distance.
enum DragType {
    case undecided
    case horizontal     //image pager owns it
    case scrollOwned    //details scroll owns it; may hand off to .details at the top
    case details        //moving the details card between detents
    case dismiss        //pulling the whole profile down
}

//One drag gesture for the whole profile. It decides once what the finger means
//(page images / scroll details / move the card / dismiss the profile) and from then
//on only writes detailsOffset or profileOffset — both transform-only leaves — so
//tracking never triggers a layout pass.
extension ProfileView {

    //Measured in .global to match restingCardTopGlobal, the card-boundary reference.
    func profileDrag(geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                //A committed close owns the surface; new touches wait for the
                //next presentation so animation states can never conflict.
                guard morph?.phase != .closing else { return }
                if ui.dragType == .undecided {
                    let x = value.translation.width
                    let y = value.translation.height
                    guard abs(x) > 6 || abs(y) > 6 else { return }
                    ui.dragType = abs(y) > abs(x) ? classifyVertical(value) : .horizontal
                    if ui.dragType == .details { commitDetailsDrag(value) }
                    if ui.dragType == .dismiss { commitDismissDrag(value) }
                }
                //An open card hands off from scrolling the moment the content tops out
                //while the finger is still pulling down.
                if ui.dragType == .scrollOwned, ui.isAtTopOfScroll, value.translation.height > 0 {
                    ui.dragType = .details
                    commitDetailsDrag(value)
                }

                let relative = value.translation.height - ui.dragCommitTranslation
                switch ui.dragType {
                case .details:
                    let offset = rubberBand(value: ui.dragBase + relative,
                                            min: ui.detailsOpenOffset,
                                            max: ui.detailsClosedOffset,
                                            dimension: geo.size.height)
                    ui.detailsOffset = offset
                    //Non-animated writes bypass animatableData, so keep the mirror exact.
                    ui.presentedDetailsOffset = offset
                case .dismiss:
                    //Bidirectional, both axes: down drives the shrink, up reverses
                    //it back to rest; x is the damped native-style side-follow.
                    ui.profileOffset = max(0, ui.dragBase + relative)
                    ui.profileOffsetX = ui.dragBaseX + (value.translation.width - ui.dragCommitTranslationX)
                    ui.presentedProfileOffset = ui.profileOffset
                    ui.presentedProfileOffsetX = ui.profileOffsetX
                default:
                    break
                }
            }
            .onEnded { value in
                guard morph?.phase != .closing else { ui.dragType = .undecided; return }
                defer { ui.dragType = .undecided }
                switch ui.dragType {
                case .details: endDetailsDrag(value)
                case .dismiss: endProfileDrag(value, geo: geo)
                default: break
                }
            }
    }

    //Resolve what a vertical drag means from the card state and where it started.
    private func classifyVertical(_ value: DragGesture.Value) -> DragType {
        //Resting layout top plus the live drag/animation offset = on-screen top.
        let cardTop = ui.restingCardTopGlobal + ui.presentedDetailsOffset
        let startedOnCard = value.startLocation.y >= cardTop
        if ui.detailsOpen {
            //Header above the open card always moves it; the card itself scrolls its
            //content and only follows a downward pull from the top.
            guard startedOnCard else { return .details }
            return (ui.isAtTopOfScroll && value.translation.height > 0) ? .details : .scrollOwned
        }
        if value.translation.height < 0 { return .details } //pull up anywhere opens
        //Downward when closed: rubber-band the card if the drag started on it,
        //dismiss the profile if it started on the header (own profile never dismisses).
        if startedOnCard { return .details }
        return isUserProfile ? .horizontal : .dismiss
    }

    //Snapshot the gesture so the card continues from exactly where it is on screen —
    //including mid-animation, which a plain state read would teleport past.
    private func commitDetailsDrag(_ value: DragGesture.Value) {
        //Flag first: it guards the stale snap-animation completion that the
        //interrupting write below may fire.
        ui.isDraggingDetails = true
        ui.dragCommitTranslation = value.translation.height
        ui.dragBase = ui.presentedDetailsOffset
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { ui.detailsOffset = ui.presentedDetailsOffset }
    }

    private func endDetailsDrag(_ value: DragGesture.Value) {
        guard ui.isDraggingDetails else { return }
        ui.isDraggingDetails = false
        let velocity = value.velocity.height
        //Project where momentum would land the card, then settle to the nearest
        //detent — the same selection rule as the system sheet.
        let projected = ui.detailsOffset + project(velocity: velocity)
        let willOpen = abs(projected - ui.detailsOpenOffset) < abs(projected - ui.detailsClosedOffset)
        ui.animateDetails(to: willOpen, velocity: velocity)
    }

    //Snapshot the gesture so the surface continues from exactly where it is on
    //screen — a regrab catches a snap-back spring mid-flight instead of
    //teleporting back to rest.
    private func commitDismissDrag(_ value: DragGesture.Value) {
        ui.isDismissDragging = true
        ui.dragCommitTranslation = value.translation.height
        ui.dragCommitTranslationX = value.translation.width
        ui.dragBase = ui.presentedProfileOffset
        ui.dragBaseX = ui.presentedProfileOffsetX
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            ui.profileOffset = ui.presentedProfileOffset
            ui.profileOffsetX = ui.presentedProfileOffsetX
        }
    }

    private func endProfileDrag(_ value: DragGesture.Value, geo: GeometryProxy) {
        let velocity = value.velocity.height
        //Native completes once the momentum-projected resting point passes about
        //a third of the screen — a flick projects far past it from a short drag.
        let projected = ui.profileOffset + project(velocity: velocity)
        if projected > geo.size.height * 0.3 {
            animateDismiss(releaseVelocity: velocity)
        } else {
            animateSnapBack(releaseVelocity: velocity)
        }
    }

    //Distance a free deceleration would travel (UIScrollView's .normal rate).
    private func project(velocity: CGFloat) -> CGFloat {
        let rate: CGFloat = 0.998
        return (velocity / 1000) * rate / (1 - rate)
    }

    //UIScrollView's rubber band: f(x) = (x·d·c) / (d + c·x) with c = 0.55 and
    //d = the view dimension. Approaches d asymptotically — the generous, gradual
    //resistance of the system sheet pulled past its range.
    private func rubberBand(value: CGFloat, min lo: CGFloat, max hi: CGFloat, dimension d: CGFloat) -> CGFloat {
        let c: CGFloat = 0.55
        func band(_ x: CGFloat) -> CGFloat { (x * d * c) / (d + c * x) }
        if value > hi { return hi + band(value - hi) }
        if value < lo { return lo - band(lo - value) }
        return value
    }
}

//MARK: - Drag effect leaves
//The bodies below are the ONLY thing SwiftUI re-evaluates per drag frame: the
//per-frame offsets live in ProfileUIState and only these modifiers read them.
//All of them are transforms or opacity — none can trigger a layout pass.

//Card position + lift. This leaf owns the per-frame read of detailsOffset and
//hands the value to the Animatable modifier below.
struct DetailsCardDragEffect: ViewModifier {
    var ui: ProfileUIState
    func body(content: Content) -> some View {
        content.modifier(AnimatedCardOffset(offset: ui.detailsOffset, ui: ui))
    }
}

//During a snap spring the animation system interpolates animatableData every frame;
//the setter mirrors those values into presentedDetailsOffset so a new drag can catch
//the card mid-flight (geometry readers can't see .offset transforms, so this is the
//only true source of the card's on-screen position). Scale derives from the same
//interpolated value so it can never desync from the offset. Anchoring the scale to
//.top keeps the card edge glued to the finger (a centre anchor makes the top edge
//creep as the scale changes).
struct AnimatedCardOffset: ViewModifier, Animatable {
    var offset: CGFloat
    var ui: ProfileUIState

    var animatableData: CGFloat {
        get { offset }
        set {
            offset = newValue
            ui.presentedDetailsOffset = newValue
        }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(0.97 + 0.03 * ui.progress(for: offset), anchor: .top)
            .offset(y: offset)
    }
}

//Header (title + image) slides up as the card opens.
struct ProfileHeaderDragEffect: ViewModifier {
    var ui: ProfileUIState
    func body(content: Content) -> some View {
        content.offset(y: ui.interpolate(from: 0, to: -90))
    }
}

//Opacity tied to drag progress over a sub-range.
struct DetailsFadeEffect: ViewModifier {
    var ui: ProfileUIState
    let from: CGFloat
    let to: CGFloat
    var impactStart: CGFloat = 0
    var impactEnd: CGFloat = 1
    func body(content: Content) -> some View {
        content.opacity(ui.interpolate(from: from, to: to, impactStart: impactStart, impactEnd: impactEnd))
    }
}

//Invite button drops toward the bottom edge as details open.
struct InviteButtonDragEffect: ViewModifier {
    var ui: ProfileUIState
    func body(content: Content) -> some View {
        content.offset(y: ui.interpolate(from: 0, to: 144))
    }
}
