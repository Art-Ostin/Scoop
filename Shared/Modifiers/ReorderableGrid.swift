//
//  ReorderableGrid.swift
//  Scoop
//
//  Created by Art Ostin on 21/09/2026.
//

import SwiftUI
import UIKit

//Hold a photo to lift it, drag it over the others, let go to drop it in. Everything a reorder does lives in this file:
//  .reorderableGrid(order) { from, to in } preview: { id, slot in }   on the grid: the lift, the drag, the haptics, the drop
//  .reorderableCell(id, canLift:)                                      on each cell: its rest frame, its hole, its slide
//  .reorderLiftLayer(isReordering:)                                    on the List around a grid whose row clips it
//  ReorderSlotReader(slot:) { slot in }                                inside a cell whose look depends on its slot
//The lift is a UIKit long press on purpose: every SwiftUI LongPress/Drag pairing either starves the List's scroll from
//touch-down or lets the cell's own Button fire after the drop (measured on iOS 26 and 27).

// MARK: - Call sites

extension View {

    //On the grid. `order` is the movable cells' ids in screen order, and the grid's ForEach must be keyed by the same ids,
    //so the drop is a layout move. `onMove(from, to)` runs ONCE per drop, as the finger lets go, with `Array.reorder`'s
    //shift/insert. `preview(id, slot)` is the item in the air as it looks in `slot`: the cell's own face without its
    //Button, so the landing hands off onto an identical twin. `pressScale` and `pressResponse` are the cell's own press:
    //its depth and its critically damped spring (nil: no spring, already at depth), so the photo rises out of exactly
    //the pose that press has reached when the lift fires.
    func reorderableGrid<ID: Hashable, Preview: View>(
        _ order: [ID],
        pressScale: CGFloat = 1,
        pressResponse: TimeInterval? = nil,
        onMove: @escaping (_ from: Int, _ to: Int) -> Void,
        @ViewBuilder preview: @escaping (_ id: ID, _ slot: Int) -> Preview
    ) -> some View {
        modifier(ReorderableGrid(order: order,
                                 liftPose: ReorderStyle.liftPose(depth: pressScale, response: pressResponse),
                                 onMove: onMove, preview: preview))
    }

    //On each cell, outside any Button or zoom wrapper. A cell whose id isn't in the grid's `order` never moves;
    //`canLift: false` keeps it in the shuffle as a drop target that is never picked up itself
    func reorderableCell(_ id: some Hashable, canLift: Bool = true) -> some View {
        modifier(ReorderableCell(id: AnyHashable(id), canLift: canLift))
    }

    //On the List or ScrollView around a grid whose row clips it: the lifted photo is drawn up here, the scroll holds
    //still under it, and `isReordering` mirrors lift → landing for a cover's dismiss lock
    func reorderLiftLayer(isReordering: Binding<Bool>? = nil) -> some View {
        modifier(ReorderLiftHost(isReordering: isReordering))
    }
}

extension Array {
    //Shift/insert, the one reorder rule: the element leaves `from`, the ones between close up behind it, it lands at `to`
    mutating func reorder(from: Int, to: Int) {
        guard from != to, indices.contains(from), indices.contains(to) else { return }
        insert(remove(at: from), at: to)
    }
}

//A cell's face for the slot it shows in right now, so a slot-shaped look (a grid-corner radius) slides with the cell
struct ReorderSlotReader<Content: View>: View {

    //Injected
    @Environment(\.reorderSlot) private var liveSlot
    let slot: Int
    @ViewBuilder let content: (Int) -> Content

    var body: some View { content(liveSlot ?? slot) }
}

extension EnvironmentValues {
    @Entry var reorderSlot: Int? = nil //Mid-drag, the slot a cell has slid to; nil at rest, where its own slot is the truth
}

// MARK: - Tuning

private enum ReorderStyle {
    static let liftDelay: TimeInterval = 0.15 //Held this long, still, a photo lifts; a finger that moves first is scrolling. The floor: much below this, a slow tap lifts instead of opening the editor
    static let liftScale: CGFloat = 1.05 //The photo in the hand rides a touch larger than its slot
    static let slop: CGFloat = 10 //Geometry: UIKit's own long-press allowable movement
    static let hysteresis: CGFloat = 8 //Geometry: a new slot must be this much nearer before the cells move, so a boundary never flickers
    static let pullLimit: CGFloat = 16 //Geometry: the furthest the photo gives past the grid's edge
    static let rubberBand: CGFloat = 0.55 //UIScrollView's own rubber-band coefficient

    //How far a cell's own press has shrunk it when the lift fires: its spring evaluated at the lift delay, not an animation
    static func liftPose(depth: CGFloat, response: TimeInterval?) -> CGFloat {
        guard let response else { return depth }
        return Spring(response: response, dampingRatio: 1)
            .value(fromValue: 1, toValue: depth, initialVelocity: 0, time: liftDelay)
    }
}

// MARK: - Session

//One lift, start to finish: the gesture writes it; the cells, the floating copy and the haptics read it
@MainActor @Observable private final class ReorderSession {

    enum Phase { case idle, lifted, settling, handingOff }

    //A VoiceOver move, carried out by the grid, which owns the order
    struct Step: Equatable {
        let id: AnyHashable
        let delta: Int
        let serial: Int
    }

    //The lift
    private(set) var phase: Phase = .idle
    private(set) var lifted: AnyHashable? //In the air; its own cell stays mounted, hidden, until the hand-off
    private(set) var target = 0 //The slot it would land in
    private(set) var lifts = 0 //Lift haptic
    private(set) var shifts = 0 //Slot-change haptic
    private(set) var step: Step?
    var movable: Set<AnyHashable> = [] //The grid's order, so a cell knows whether VoiceOver may move it

    //The floating copy
    private(set) var copy: ((Int) -> AnyView)?
    private(set) var copySize: CGSize = .zero
    private(set) var copyCenter: CGPoint = .zero //Grid space
    private(set) var copyScale: CGFloat = 1
    private(set) var copyLift: Double = 0 //Shadow strength: in with the lift, out with the settle
    private(set) var copyOpacity: Double = 0

    //Geometry, measured by the views, so never observed
    let space = UUID() //The grid's named coordinate space
    @ObservationIgnored var frames: [AnyHashable: CGRect] = [:] //Rest frames, grid space
    @ObservationIgnored var liftable: [AnyHashable: Bool] = [:]
    @ObservationIgnored var layerOrigin: CGPoint = .zero //Global
    @ObservationIgnored private(set) var generation = 0 //A settle or fade finishing after a newer lift stands down
    @ObservationIgnored private var gridOrigin: CGPoint = .zero //Global, taken at the lift
    @ObservationIgnored private var slots: [CGRect] = [] //Grid space, by position, taken at the lift
    @ObservationIgnored private var positions: [AnyHashable: Int] = [:]
    @ObservationIgnored private var bounds: CGRect = .zero
    @ObservationIgnored private var home = 0
    @ObservationIgnored private var grab: CGSize = .zero //Finger to copy centre, fixed at the lift
    @ObservationIgnored private var restScale: CGFloat = 1

    //From the lift until the copy lands: the scroll, the cover's dismissal and every cell hold still
    var isActive: Bool { phase == .lifted || phase == .settling }

    var copyPosition: CGPoint {
        CGPoint(x: gridOrigin.x + copyCenter.x - layerOrigin.x, y: gridOrigin.y + copyCenter.y - layerOrigin.y)
    }

    func hides(_ id: AnyHashable) -> Bool { lifted == id }

    func takesTouches(_ id: AnyHashable) -> Bool {
        switch phase {
        case .idle, .handingOff: true
        case .lifted: id == lifted //The lifting touch keeps its path; a second finger finds nothing to tap
        case .settling: false //Nothing opens from a cell still sliding home
        }
    }

    //Where a resting cell shows mid-drag, relative to its slot
    func offset(of id: AnyHashable) -> CGSize {
        guard phase == .lifted, id != lifted, let at = positions[id], slots.indices.contains(at) else { return .zero }
        let to = previewSlot(of: at)
        return CGSize(width: slots[to].minX - slots[at].minX, height: slots[to].minY - slots[at].minY)
    }

    //The slot a cell shows in mid-drag; nil once the order itself says where it is
    func liveSlot(of id: AnyHashable) -> Int? {
        guard phase == .lifted, let at = positions[id] else { return nil }
        return id == lifted ? target : previewSlot(of: at)
    }

    func lift(_ id: AnyHashable, at point: CGPoint, order ids: [AnyHashable], slots: [CGRect], gridOrigin: CGPoint,
              copy: @escaping (Int) -> AnyView) -> Bool {
        guard phase == .idle, let home = ids.firstIndex(of: id), slots.count == ids.count else { return false }
        generation += 1
        self.home = home
        self.slots = slots
        self.gridOrigin = gridOrigin
        positions = Dictionary(zip(ids, ids.indices), uniquingKeysWith: { first, _ in first })
        bounds = slots.reduce(slots[home]) { $0.union($1) }
        let rest = slots[home]
        grab = CGSize(width: point.x - rest.midX, height: point.y - rest.midY)
        //One frame: the copy lands on the pressed cell exactly as it looks, and the cell becomes its hole
        withTransaction(Self.instant) {
            self.copy = copy
            copySize = rest.size
            copyCenter = CGPoint(x: rest.midX, y: rest.midY)
            copyOpacity = 1
            lifted = id
            target = home
            phase = .lifted
            lifts += 1
        }
        //Then it snaps up out of the press into the hand, one beat with the haptic
        withAnimation(.toggle) {
            copyScale = ReorderStyle.liftScale
            copyLift = 1
        }
        return true
    }

    //The copy rides the finger; once another slot is clearly nearer, the cells between make room
    func track(_ point: CGPoint) {
        guard phase == .lifted else { return }
        copyCenter = pulled(CGPoint(x: point.x - grab.width, y: point.y - grab.height))
        let next = nearestSlot(to: copyCenter)
        guard next != target else { return }
        withAnimation(.move) { target = next }
        shifts += 1
    }

    //The drop, inside the grid's `.move`: the offsets hand over to the new layout and the copy flies to its slot
    func settle(returningHome: Bool) {
        guard phase == .lifted else { return }
        if returningHome { target = home }
        guard slots.indices.contains(target) else { return }
        phase = .settling
        copyCenter = CGPoint(x: slots[target].midX, y: slots[target].midY)
        copyScale = 1
        copyLift = 0
    }

    //The copy sits on its slot: show the cell under it, then dissolve the copy over its identical twin
    func handOff(_ lift: Int) {
        guard lift == generation, phase == .settling else { return }
        withTransaction(Self.instant) {
            lifted = nil
            phase = .handingOff
        }
        withAnimation(.handOff, completionCriteria: .removed) {
            copyOpacity = 0
        } completion: { [weak self] in
            guard let self, lift == self.generation, self.phase == .handingOff else { return }
            self.reset()
        }
    }

    //Back to rest with nothing animating; also the way out when the grid vanishes mid-lift
    func reset() {
        withTransaction(Self.instant) {
            phase = .idle
            lifted = nil
            copy = nil
            copyOpacity = 0
            copyLift = 0
            copyScale = restScale
        }
    }

    //The pose the next copy rises from, committed while it is invisible so the lift has a from-value
    func rest(at scale: CGFloat) {
        restScale = scale
        guard phase == .idle, copyScale != scale else { return }
        withTransaction(Self.instant) { copyScale = scale }
    }

    func requestStep(_ id: AnyHashable, by delta: Int) {
        step = Step(id: id, delta: delta, serial: (step?.serial ?? 0) + 1)
    }
}

extension ReorderSession {

    //Shift/insert: the lifted item leaves `home`, and everything between it and `target` steps one slot toward the gap
    private func previewSlot(of at: Int) -> Int {
        if home < target, (home + 1...target).contains(at) { return at - 1 }
        if target < home, (target..<home).contains(at) { return at + 1 }
        return at
    }

    //The slot nearest the copy's centre; a new one must be clearly nearer than the current one
    private func nearestSlot(to point: CGPoint) -> Int {
        func distance(_ slot: Int) -> CGFloat { hypot(slots[slot].midX - point.x, slots[slot].midY - point.y) }
        guard slots.indices.contains(target), let nearest = slots.indices.min(by: { distance($0) < distance($1) }) else { return target }
        return distance(nearest) + ReorderStyle.hysteresis < distance(target) ? nearest : target
    }

    //Free inside the grid; past its edge the copy follows with a rising give
    private func pulled(_ point: CGPoint) -> CGPoint {
        let halfWidth = copySize.width / 2
        let halfHeight = copySize.height / 2
        return CGPoint(x: Self.rubberBand(point.x, bounds.minX + halfWidth, bounds.maxX - halfWidth),
                       y: Self.rubberBand(point.y, bounds.minY + halfHeight, bounds.maxY - halfHeight))
    }

    private static func rubberBand(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        let high = max(low, high)
        let limit = ReorderStyle.pullLimit
        func give(_ excess: CGFloat) -> CGFloat { limit * (1 - 1 / (excess * ReorderStyle.rubberBand / limit + 1)) }
        if value < low { return low - give(low - value) }
        if value > high { return high + give(value - high) }
        return value
    }

    private static var instant: Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }
}

// MARK: - The grid

private struct ReorderableGrid<ID: Hashable, Preview: View>: ViewModifier {

    //Injected
    @Environment(ReorderSession.self) private var hosted: ReorderSession?
    @Environment(\.scenePhase) private var scenePhase
    let order: [ID]
    let liftPose: CGFloat //The pressed cell's scale at the lift, where the copy rises from
    let onMove: (Int, Int) -> Void
    let preview: (ID, Int) -> Preview

    //Local view state
    @State private var own = ReorderSession() //Used only when no `.reorderLiftLayer()` sits above the grid

    private var session: ReorderSession { hosted ?? own }

    func body(content: Content) -> some View {
        let session = session
        content
            .coordinateSpace(.named(session.space))
            .gesture(ReorderLiftGesture(space: session.space,
                                        canLift: { canLift(at: $0) },
                                        onLift: { lift(at: $0, gridOrigin: $1) },
                                        onMove: { session.track($0) },
                                        onDrop: { drop(cancelled: $0) }))
            .environment(session)
            .overlay { if hosted == nil { ReorderLiftLayer(session: session) } }
            .zIndex(session.phase == .idle ? 0 : 1) //Above the grid's later siblings while a photo is up
            .sensoryFeedback(.impact(weight: .medium), trigger: session.lifts)
            .sensoryFeedback(.selection, trigger: session.shifts)
            .onChange(of: order, initial: true) { _, order in session.movable = Set(order.map { AnyHashable($0) }) }
            .onChange(of: session.step) { _, step in if let step { move(step) } }
            .onAppear { session.rest(at: liftPose) }
            .onChange(of: scenePhase) { _, phase in if phase != .active { drop(cancelled: true) } } //Backs up the touch's own cancel
            .onDisappear { abandon() } //A torn-down grid never hears its touch end
    }
}

extension ReorderableGrid {

    //Only a liftable item, only at rest, only when there is somewhere else for it to go
    private func canLift(at point: CGPoint) -> Bool {
        guard session.phase == .idle, order.count > 1, let id = item(at: point) else { return false }
        return session.liftable[id] ?? false
    }

    private func item(at point: CGPoint) -> AnyHashable? {
        order.lazy.map { AnyHashable($0) }.first { session.frames[$0]?.contains(point) ?? false }
    }

    private func lift(at point: CGPoint, gridOrigin: CGPoint) -> Bool {
        guard canLift(at: point), let id = item(at: point) else { return false }
        let ids = order.map { AnyHashable($0) }
        let slots = ids.compactMap { session.frames[$0] }
        guard let home = ids.firstIndex(of: id) else { return false }
        let item = order[home]
        let preview = preview
        return session.lift(id, at: point, order: ids, slots: slots, gridOrigin: gridOrigin) { slot in
            AnyView(preview(item, slot))
        }
    }

    //The order changes once, here, inside the `.move` the copy settles on, so the cells' layout move and their offsets
    //letting go cancel exactly. A cancelled touch (a call, a system swipe) lands nothing and takes everything home
    private func drop(cancelled: Bool) {
        let session = session
        guard session.phase == .lifted, let id = session.lifted else { return }
        let lift = session.generation
        let landing = session.target
        withAnimation(.move, completionCriteria: .logicallyComplete) {
            if !cancelled { commit(id, to: landing) }
            session.settle(returningHome: cancelled)
        } completion: {
            session.handOff(lift)
        }
    }

    //The grid left mid-lift (a second finger on other chrome, the screen closing): nothing lands, nothing stays locked
    private func abandon() {
        guard session.phase != .idle else { return }
        session.reset()
    }

    //VoiceOver's move actions: one slot at a time, the same shift/insert as a drag
    private func move(_ step: ReorderSession.Step) {
        guard session.phase == .idle, let from = order.firstIndex(where: { AnyHashable($0) == step.id }),
              order.indices.contains(from + step.delta) else { return }
        withAnimation(.move) { onMove(from, from + step.delta) }
    }

    private func commit(_ id: AnyHashable, to target: Int) {
        guard let from = order.firstIndex(where: { AnyHashable($0) == id }), from != target,
              order.indices.contains(target) else { return }
        onMove(from, target)
    }
}

// MARK: - One cell

private struct ReorderableCell: ViewModifier {

    //Injected
    @Environment(ReorderSession.self) private var session: ReorderSession?
    let id: AnyHashable
    let canLift: Bool

    func body(content: Content) -> some View {
        if let session {
            let space = session.space
            content
                .environment(\.reorderSlot, session.liveSlot(of: id)) //Read by `ReorderSlotReader` inside the cell
                .opacity(session.hides(id) ? 0 : 1) //The hole: it stays mounted, because it owns the touch that lifted it
                .offset(session.offset(of: id)) //Making room, render-only: the grid's layout never moves mid-drag
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(space)) } action: { session.frames[id] = $0 } //Outside the offset: the rest slot
                .allowsHitTesting(session.takesTouches(id))
                .onChange(of: canLift, initial: true) { _, canLift in session.liftable[id] = canLift }
                .accessibilityActions { if canLift, session.movable.contains(id) { moveActions(in: session) } }
        } else {
            content
        }
    }

    @ViewBuilder
    private func moveActions(in session: ReorderSession) -> some View {
        Button("Move Earlier") { session.requestStep(id, by: -1) }
        Button("Move Later") { session.requestStep(id, by: 1) }
    }
}

// MARK: - The lift layer

private struct ReorderLiftHost: ViewModifier {

    //Injected
    let isReordering: Binding<Bool>?

    //Local view state
    @State private var session = ReorderSession()

    func body(content: Content) -> some View {
        content
            .environment(session)
            .scrollDisabled(session.isActive) //SwiftUI's own writer: a UIKit freeze is undone by the List's next update
            .overlay { ReorderLiftLayer(session: session) }
            .onChange(of: session.isActive) { _, active in isReordering?.wrappedValue = active }
            .onDisappear { isReordering?.wrappedValue = false }
    }
}

//The item in the air, drawn above everything it passes over
private struct ReorderLiftLayer: View {

    //Injected
    let session: ReorderSession

    private var copy: some View {
        (session.copy?(session.target) ?? AnyView(EmptyView()))
            .frame(width: session.copySize.width, height: session.copySize.height)
            .scaleEffect(session.copyScale)
            .shadow(.floating, strength: session.copyLift)
            .opacity(session.copyOpacity)
            .position(session.copyPosition)
    }

    var body: some View {
        Color.clear
            .overlay { copy }
            .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { session.layerOrigin = $0 }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - The lift gesture

//A UIKit long press on the grid: until it fires, the scroll, the cover and the cells' own taps keep the touch
private struct ReorderLiftGesture: UIGestureRecognizerRepresentable {

    //Injected
    let space: UUID
    let canLift: (CGPoint) -> Bool
    let onLift: (_ point: CGPoint, _ gridOrigin: CGPoint) -> Bool
    let onMove: (CGPoint) -> Void
    let onDrop: (_ cancelled: Bool) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(converter: converter)
    }

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let press = UILongPressGestureRecognizer()
        press.minimumPressDuration = ReorderStyle.liftDelay
        press.allowableMovement = ReorderStyle.slop
        press.delegate = context.coordinator
        return press
    }

    func updateUIGestureRecognizer(_ press: UILongPressGestureRecognizer, context: Context) {
        context.coordinator.space = space
        context.coordinator.canLift = canLift
    }

    func handleUIGestureRecognizerAction(_ press: UILongPressGestureRecognizer, context: Context) {
        let point = context.converter.location(in: .named(space))
        switch press.state {
        case .began:
            let global = context.converter.location(in: .global)
            guard onLift(point, CGPoint(x: global.x - point.x, y: global.y - point.y)) else { return }
            context.coordinator.cancelSiblings() //Load-bearing: without it the cell's own Button fires at release
        case .changed:
            onMove(point)
        case .ended:
            onDrop(false)
        case .cancelled, .failed:
            onDrop(true)
        default:
            break
        }
    }

    @MainActor final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        //Injected
        let converter: CoordinateSpaceConverter
        var space = UUID()
        var canLift: (CGPoint) -> Bool = { _ in false }

        //Local state
        private let siblings = NSHashTable<UIGestureRecognizer>.weakObjects() //The cell's own gestures on this touch

        init(converter: CoordinateSpaceConverter) {
            self.converter = converter
        }

        //A second finger never joins a lift; a fresh touch starts a fresh sibling list
        func gestureRecognizer(_ press: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard press.state == .possible else { return false }
            if press.numberOfTouches == 0 { siblings.removeAllObjects() }
            return true
        }

        func gestureRecognizerShouldBegin(_ press: UIGestureRecognizer) -> Bool {
            canLift(converter.location(in: .named(space)))
        }

        //SwiftUI's own gestures (the cell's Button or tap) share our hosting view; the scroll's and the cover's pans don't
        func gestureRecognizer(_ press: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            guard other.view === press.view else { return false }
            siblings.add(other)
            return true
        }

        //Disabling a recognizer mid-touch cancels it: the press lets go and the tap never fires
        func cancelSiblings() {
            for other in siblings.allObjects where [.possible, .began, .changed].contains(other.state) {
                other.isEnabled = false
                other.isEnabled = true
            }
            siblings.removeAllObjects()
        }
    }
}
