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

    var appState: AppState = .booting
    
    let authService: AuthServicing
    let defaultsManager: DefaultsManaging

    let userRepo: UserRepository
    let eventsRepo: EventsRepository
    let profilesRepo: ProfilesRepository
    let chatRepo: ChatRepository
    let profileLoader: ProfileLoading
    let imageLoader: ImageLoading


    //Auth listener spans the app lifetime; session streams are cancelled together on sign-out.
    private var authStreamTask: Task<Void, Never>?
    private let streams = TaskBag()
    
    //Key values need access to throughout App.
    var user: UserProfile {
        guard let sessionUser else { fatalError("Session not started") }
        return sessionUser
    }
    
    private(set) var sessionUser: UserProfile?
    private(set) var profiles: [PendingProfile] = []
    private(set) var invites: [EventProfile] = []
    private(set) var events: [EventProfile] = []
    private(set) var pastEvents: [EventProfile] = []
    
    var recentMessageReceived: MessagePopupModel?
    var activeChatEventId: String?
    
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

    //Local-session optimistic updates (called from view models before listener catches up) (Remove later)
    func updateAcceptedEventInSession(eventProfile: EventProfile) {
        events.append(eventProfile)
    }

    func removeInvitedEventInSession(id: String) {
        invites.removeAll { $0.id == id }
    }
}

//Logic dealing with the recommended Profiles shown to the User
extension SessionManager {
    
    func profilesStream() {
        subscribe("profiles", to: profilesRepo.profilesTracker(userId: user.id)) { [weak self] change in
            guard let self else { return }
            switch change {
            case .initial(let recs):
                self.profiles = try await self.profileLoader.fromIds(recs.compactMap { $0.id })
                print("profiles Loaded")
            case .added(let rec):
                if let id = rec.id {
                    self.profiles.append(contentsOf: try await self.profileLoader.fromIds([id]))
                }
            case .modified:
                break
            case .removed(let id):
                self.profiles.removeAll { $0.id == id }
            }
        }
    }
}

//Logic dealing with the popups in the app shown to the User
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
}
