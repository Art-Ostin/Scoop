//
//  ChatViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI
import os

private let chatLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Scoop", category: "chat")

@MainActor
@Observable
final class ChatViewModel {

    let defaults: DefaultsManaging
    let session: Session
    let chatRepo: ChatRepository
    let imageLoader: ImageLoading
    let eventProfile: EventProfile

    var messages: [ChatMessage] = []
    //Own messages the server has not confirmed yet: their bubbles show a clock until the server's timestamp arrives
    var pendingIds: Set<String> = []

    //Ids whose listener echo has arrived: the write sits in Firestore's local store and will reach the server,
    //so a throw after it is the thread bookkeeping failing behind a message that is already sent
    @ObservationIgnored private var echoed: Set<String> = []

    init(defaults: DefaultsManaging, session: Session, chatRepo: ChatRepository, imageLoader: ImageLoading, eventProfile: EventProfile) {
        self.defaults = defaults
        self.session = session
        self.chatRepo = chatRepo
        self.imageLoader = imageLoader
        self.eventProfile = eventProfile
    }

    var userId: String {session.user.id}

    func isMyChat(_ message: ChatMessage) -> Bool {
        message.authorId == userId
    }

    func isNextNewAuthor(for message: ChatMessage) -> Bool {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return true }
        guard idx < messages.count - 1 else { return true }
        let next = messages[idx + 1]
        return next.authorId != message.authorId || isNewDay(for: next)
    }

    func isNewDay(for message: ChatMessage) -> Bool {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return true }
        guard idx > 0 else { return true }
        guard let lastDay = messages[idx - 1].dateCreated else { return false }
        let newDay = message.dateCreated ?? Date()
        return !Calendar.current.isDate(lastDay, inSameDayAs: newDay)
    }

    //A message still waiting on the server: staged here and not yet stamped, or loaded with its timestamp unresolved
    func isPending(_ message: ChatMessage) -> Bool {
        guard let id = message.id else { return false }
        return pendingIds.contains(id) || (message.dateCreated == nil && isMyChat(message))
    }

    //MARK: Sending — staged at T0 inside the bar's transaction, committed behind the flight

    //The id the row keeps for life, minted before the write: the listener's echo then merges into the
    //row the sender already shows instead of replacing it (a replaced id re-creates the row and kills
    //anything riding it).
    func newMessageId() -> String {
        chatRepo.newMessageId(eventId: eventProfile.id)
    }

    //The optimistic row. Appended inside the caller's transaction so its insertion rides the caller's curve;
    //a flying send has already registered `id` with its flight, so the row mounts as a ghost.
    @discardableResult
    func stage(text: String, id: String, at date: Date = Date()) -> ChatMessage {
        var message = ChatMessage(authorId: userId, recipientId: eventProfile.profile.id, content: text)
        message.id = id
        message.dateCreated = date
        pendingIds.insert(id)
        messages.append(message)
        return message
    }

    //The write behind a staged row. Throws for the container to surface; what happens to the row is `discard`'s call.
    func commit(_ message: ChatMessage) async throws {
        guard let id = message.id else { return }
        try await chatRepo.sendMessage(id: id, text: message.content, eventId: eventProfile.id, userId: userId, recipientId: eventProfile.profile.id)
    }

    //After a failed commit: removes the staged row of a send that never left, and says so. A row whose echo has
    //merged stays — its message is stored and on its way, only the bookkeeping behind it failed, which is logged.
    @discardableResult
    func discard(_ id: String?, after error: Error) -> Bool {
        guard let id else { return false }
        guard !echoed.contains(id) else {
            chatLog.error("send \(id, privacy: .public) is stored; its thread bookkeeping failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
        pendingIds.remove(id)
        withAnimation(.move) {
            messages.removeAll { $0.id == id }
        }
        return true
    }

    func loadImages(profile: EventProfile) async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile.profile)
    }

    func startListening() async {
        do {
            for try await change in chatRepo.messagesTracker(eventId: eventProfile.id) {
                switch change {
                case .initial(let initial):
                    self.messages = initial.reversed()
                case .added(let message):
                    //Our own send echoes back within milliseconds; anything else is a received message
                    if !merge(message) {
                        withAnimation(.move) {
                            self.messages.append(message)
                        }
                    }
                case .modified(let message):
                    merge(message)
                case .removed(let id):
                    withAnimation(.move) {
                        self.messages.removeAll { $0.id == id }
                    }
                }
            }
        } catch {
            chatLog.error("messages stream ended: \(error.localizedDescription, privacy: .public)")
        }
    }

    //The echo of a row we already hold, merged field by field with animations off: the optimistic date
    //survives until the server stamp resolves (a pending @ServerTimestamp decodes nil), and a same-value
    //echo (`.modified` arrives twice, pending then acked) writes nothing.
    @discardableResult
    private func merge(_ echo: ChatMessage) -> Bool {
        guard let idx = messages.firstIndex(where: { $0.id == echo.id }) else { return false }
        if let id = echo.id {
            echoed.insert(id)
            //The server's timestamp is the confirmation: the clock gives way to the time. Cleared in a later transaction,
            //so the merge's disabled animations below cannot swallow the badge's blur replace.
            if echo.dateCreated != nil, pendingIds.contains(id) || messages[idx].dateCreated == nil {
                pendingIds.insert(id) //A row loaded unstamped keeps its clock through the merge
                Task { @MainActor in self.pendingIds.remove(id) }
            }
        }
        var merged = echo
        merged.dateCreated = echo.dateCreated ?? messages[idx].dateCreated
        guard merged != messages[idx] else { return true }
        var settle = Transaction()
        settle.disablesAnimations = true
        withTransaction(settle) { messages[idx] = merged }
        return true
    }
}

//MARK: - UI state

//Ephemeral chat view state: the scroll container's width, the composer's measured frames, the send
//button's press, and every send flight in progress. Created by the container, read by the bar and the list.
@MainActor
@Observable
final class ChatUIState {

    static let space = "chat" //The container's named coordinate space: the bar and the list both measure in it

    var containerWidth: CGFloat = 0
    var fieldFrame: CGRect = .zero //The draft field at rest (measured outside its press lift), in the chat space
    var barFrame: CGRect = .zero //The input bar, the flight layer's host; its top is the list's floor
    var sendPressed = false
    var flights: [SendFlight] = []
    //Whether the list rests at its floor and whether the field holds a draft — observed, and written only when they
    //flip: together they pin the list to its floor while a draft grows the field, so the last message stays in view
    //and the field's collapse at T0 leaves the list exactly at its floor for the flight
    var atFloor = true
    var hasDraft = false

    //How far the list rests above its floor: 0 at the bottom, negative for a thread shorter than the screen.
    //Written on every scroll tick and read only by a send at T0, so never observed.
    @ObservationIgnored var distanceFromFloor: CGFloat = 0

    //The ghost rows' laid-out bodies, per flight. Reported on every frame the list shifts; the clones read them
    //while re-rendering each frame anyway, where an observed write would re-render every row per frame.
    @ObservationIgnored private var bodyFrames: [UUID: CGRect] = [:]

    func flight(for messageId: String?) -> SendFlight? {
        guard let messageId else { return nil }
        return flights.first { $0.messageId == messageId }
    }

    func phase(for messageId: String?) -> SendFlight.Phase? {
        flight(for: messageId)?.phase
    }

    func index(of flightId: UUID) -> Int? {
        flights.firstIndex { $0.id == flightId }
    }

    func reportBody(frame: CGRect, for messageId: String?) {
        guard let messageId, let flight = flights.first(where: { $0.messageId == messageId }) else { return }
        bodyFrames[flight.id] = frame
    }

    func forget(_ flightId: UUID) {
        bodyFrames[flightId] = nil
    }

    //Where a flight's body comes to rest, read live: on the trailing line, at the higher of two tops — the row's
    //own (a short thread never shifts; a later send carries an earlier row up) and its run gap above the floor
    //(a full list keeps its bottom anchored, so a row still growing in ends there). The floor is the bar's top
    //now, so a collapsing field or a keyboard leaving mid-flight carries the landing with it.
    func landing(for flight: SendFlight) -> CGRect {
        let body = bodyFrames[flight.id]
        let size = body.map { CGSize(width: $0.width.rounded(), height: $0.height.rounded()) } ?? flight.rowSize
        let anchoredTop = barFrame.minY - BubbleMetrics.runGap - size.height
        let top = body.map { min($0.minY.rounded(), anchoredTop) } ?? anchoredTop
        return CGRect(x: flight.trailingX - size.width, y: top, width: size.width, height: size.height)
    }
}

//One send: flying from T0 on its own clock, landed when the row shows beneath it, dissolving as the clone
//fades over the identical row.
struct SendFlight: Identifiable {
    enum Phase { case flying, landed, dissolving }

    let id = UUID()
    var messageId: String? = nil
    let text: String //What is sent
    let birth: CGRect //The draft field's resting frame at T0, chat space
    var rowSize: CGSize = .zero //The resting body computed at T0: the row's growth target, and the clone's size until the row reports its own
    var textWidth: CGFloat = 0 //The width the row's text wraps against (the column, less insets and any inline badge)
    var trailingX: CGFloat = 0 //The own-bubble column's trailing edge, chat space
    var isMultiline = false //The field's wrap and the row's differ: the clone's text is posed at the row's and veiled in
    var timeline: KeyframeTimeline<SendPose>
    var start: Date? = nil //T0: the flight layer samples every pose from the time since
    var phase: Phase = .flying

    var rowHeight: CGFloat { rowSize.height + BubbleMetrics.runGap }
}

//The normalised send pose, sampled from SendChoreography's timeline at the flight's elapsed time
struct SendPose {
    var contraction: CGFloat //0 → 1 along the width ease
    var scale: CGFloat //The text/uniform scale s
    var rise: CGFloat //0 → 1 (plus overshoot) of the travel from birth to landing
    var opacity: CGFloat
    var radius: CGFloat
}
