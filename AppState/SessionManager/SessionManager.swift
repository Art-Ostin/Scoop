//
//  SessionManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI

enum ShowProfilesState {
    case active, closed, respond
}

@MainActor
//Creat a 'Task Bag' to hold all the stream Tasks. Then can cancel them later
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
@Observable class SessionManager {

    //1. All the repositories used in manager
    var appState: AppState = .booting
    let authService: AuthServicing
    let defaultsManager: DefaultsManaging
    let userRepo: UserRepository
    let eventsRepo: EventsRepository
    let profilesRepo: ProfilesRepository
    let chatRepo: ChatRepository
    let profileLoader: ProfileLoading
    let imageLoader: ImageLoading

    //2. The listeners the app holds. Deleted when session stops. (Need seperate listener for App State)
    private let streams = TaskBag()
    private var authStreamTask: Task<Void, Never>?
    
    //3. All the properties used throughout the app. (1) User (2) Profils Recommmended (3) Events upcoming, (4) past events...
    private(set) var sessionUser: UserProfile?
    var user: UserProfile {
        guard let sessionUser else { fatalError("Session not started") }
        return sessionUser
    }
    var profiles: [PendingProfile] = []
    private(set) var invites: [EventProfile] = []
    private(set) var events: [EventProfile] = []
    private(set) var pastEvents: [EventProfile] = []
    
    //4. Logic to do with popups (should be deleted later)
    var recentMessageReceived: MessagePopupModel?
    var activeChatEventId: String?
    
    var profilesHaveLoaded: Bool = false 
    
    init(
        authService: AuthServicing,
        defaultsManager: DefaultsManaging,
        userRepo: UserRepository,
        eventsRepo: EventsRepository,
        profilesRepo: ProfilesRepository,
        chatRepo: ChatRepository,
        profileLoader: ProfileLoading,
        imageLoader: ImageLoading)
    {
        self.authService = authService
        self.defaultsManager = defaultsManager
        self.userRepo = userRepo
        self.eventsRepo = eventsRepo
        self.profilesRepo = profilesRepo
        self.chatRepo = chatRepo
        self.profileLoader = profileLoader
        self.imageLoader = imageLoader
    }
}

extension SessionManager {

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
}

extension SessionManager {

    func setInitialEvents(invites: [EventProfile], active: [EventProfile], past: [EventProfile]) {
        self.invites = invites
        self.events = active
        self.pastEvents = past
    }

    func appendInvites(_ profiles: [EventProfile]) {
        invites.append(contentsOf: profiles)
    }

    func acceptInvite(eventId: String) {
        guard let i = invites.firstIndex(where: { $0.event.id == eventId }) else { return }
        events.append(invites.remove(at: i))
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
}
 
//Logic dealing with the popups in the app shown to the User (Probably remove later ad have notification section)
extension SessionManager {
    
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

    private func presentPopup(_ popup: MessagePopupModel) {
        guard popup.eventId != activeChatEventId else { return }
        recentMessageReceived = popup
        streams.insert("dismissPopup", Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.recentMessageReceived = nil
        })
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
