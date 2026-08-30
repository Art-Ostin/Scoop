//
//  Session.swift
//  Scoop
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI

enum ShowProfilesState {
    case active, closed, respond
}

@MainActor
//Holds all the stream Tasks so they can be cancelled later
final class TaskBag {
    private var tasks: [String: Task<Void, Never>] = [:]
    func insert(_ key: String, _ task: Task<Void, Never>) {
        tasks[key]?.cancel()
        tasks[key] = task
    }
    func cancel(_ key: String) {
        tasks.removeValue(forKey: key)?.cancel()
    }
    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}

@MainActor
@Observable class Session {

    //Injected
    let authService: AuthServicing
    let defaultsManager: DefaultsManaging
    let userRepo: UserRepository
    let eventsRepo: EventsRepository
    let profilesRepo: ProfilesRepository
    let chatRepo: ChatRepository
    let profileLoader: ProfileLoading
    let imageLoader: ImageLoading
    let notifications: InAppNotificationCenter

    //Listeners the app holds — cancelled when the session stops
    private let streams = TaskBag()
    private var authStreamTask: Task<Void, Never>?

    //Session state
    var appState: AppState = .booting
    private(set) var sessionUser: UserProfile?
    var profilesHaveLoaded: Bool = false
    
    var profiles: [PendingProfile] = []
    var declinedProfiles: [DeclinedProfile] = []
    
    private(set) var sentInvites: [EventProfile] = []
    private(set) var invites: [EventProfile] = []
    private(set) var events: [EventProfile] = []
    private(set) var pastEvents: [EventProfile] = []

    //The chat currently on screen, so its banners are suppressed
    var activeChatEventId: String?

    var user: UserProfile {
        guard let sessionUser else { fatalError("Session not started") }
        return sessionUser
    }

    init(
        authService: AuthServicing,
        defaultsManager: DefaultsManaging,
        userRepo: UserRepository,
        eventsRepo: EventsRepository,
        profilesRepo: ProfilesRepository,
        chatRepo: ChatRepository,
        profileLoader: ProfileLoading,
        imageLoader: ImageLoading,
        notifications: InAppNotificationCenter)
    {
        self.authService = authService
        self.defaultsManager = defaultsManager
        self.userRepo = userRepo
        self.eventsRepo = eventsRepo
        self.profilesRepo = profilesRepo
        self.chatRepo = chatRepo
        self.profileLoader = profileLoader
        self.imageLoader = imageLoader
        self.notifications = notifications
    }
}

extension Session {

    func setSessionUser(_ user: UserProfile?) {
        sessionUser = user
    }

    func setAuthStream(_ task: Task<Void, Never>?) {
        authStreamTask?.cancel()
        authStreamTask = task
    }

    func cancelAllStreams() {
        streams.cancelAll()
    }
    
    func subscribeImageLoad(for user: UserProfile) {
        streams.insert("profileImages", Task { @MainActor [weak self] in
            _ = await self?.imageLoader.loadProfileImages(user)
        })
    }
    
    //Starter switch, to load the declined profiles when app opens (in the background)
    func subscribeDeclinedLoad() {
        streams.insert("declinedProfiles", Task { @MainActor [weak self] in
            await self?.loadRecentlyDeclined()
        })
    }
}

extension Session {

    func setInitialEvents(sent: [EventProfile], invites: [EventProfile], active: [EventProfile], past: [EventProfile]) {
        self.sentInvites = sent
        self.invites = invites
        self.events = active
        self.pastEvents = past
    }

    func appendInvites(_ profiles: [EventProfile]) {
        invites.append(contentsOf: profiles)
    }

    func removeInvite(id: String) {
        invites.removeAll { $0.event.id == id }
    }

    func acceptInvite(eventId: String) {
        guard let i = invites.firstIndex(where: { $0.event.id == eventId }) else { return }
        events.append(invites.remove(at: i))
    }

    //The sender's half of acceptInvite: an invite we sent lives in sentInvites and has never been
    //in invites, so the bucket it crosses out of when they accept is a different one
    func acceptSentInvite(eventId: String) {
        guard let i = sentInvites.firstIndex(where: { $0.event.id == eventId }) else { return }
        events.append(sentInvites.remove(at: i))
    }

    func archiveEvent(eventId: String) {
        guard let i = events.firstIndex(where: { $0.event.id == eventId }) else { return }
        pastEvents.append(events.remove(at: i))
    }

    func removeEvent(id: String) {
        invites.removeAll { $0.event.id == id }
        events.removeAll { $0.event.id == id }
        pastEvents.removeAll { $0.event.id == id }
    }
    
    func updateEvent(_ event: UserEvent) {
        if let i = events.firstIndex(where: { $0.event.id == event.id }) {
            events[i].event = event
        } else if let i = pastEvents.firstIndex(where: { $0.event.id == event.id }) {
            pastEvents[i].event = event
        } else if let i = invites.firstIndex(where: { $0.event.id == event.id }) {
            invites[i].event = event
        }
    }
    
    //Logic for adding and removing 'sent' Invites
    func appendSentInvites(_ profiles: [EventProfile]) {
        sentInvites.append(contentsOf: profiles)
    }
    
    func removeSentInvite(id: String) {
        sentInvites.removeAll { $0.id == id }
    }
}
 
//Logic dealing with the popups in the app shown to the User (Probably remove later ad have notification section)
extension Session {
    
    func recentChatStream() {
        subscribe("recentChat", to: eventsRepo.eventMessageTracker(userId: user.id)) { [weak self] change in
            switch change {
            case .added(let popup), .modified(let popup):
                self?.presentPopup(popup)
            case .initial, .removed:
                break
            }
        }
    }

    private func presentPopup(_ popup: MessagePopup) {
        guard popup.eventId != activeChatEventId else { return }
        notifications.push(.newMessage(popup))
    }
    
    //Creates a Reusable Sequence throughout the session Manager
    func subscribe<S: AsyncSequence>(
        _ key: String,
        to stream: S,
        handler: @escaping (S.Element) async throws -> Void
    ) {
        streams.insert(key, Task { @MainActor in
            do {
                for try await element in stream {
                    try await handler(element)
                }
            } catch {
                print(error)
            }
        })
    }
}
