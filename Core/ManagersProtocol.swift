//
//  ManagersProtocol.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit


protocol FirestoreServicing {
    func set<T: Encodable> (_ path: String, value: T) throws
    func add<T: Encodable> (_ path: String, value: T) throws -> String
    func get<T: Decodable>(_ path: String) async throws -> T
    func increment(_ path: String, by deltas: [String: Int64])
    func update(_ path: String, fields: [String : Any]) async throws
    func delete(_ path: String) async throws
    func listenD<T: Decodable>(_ path: String) -> AsyncThrowingStream<T?, Error>
    func fetchFromCollection<T: Decodable>( _ collectionPath: String, filters: [FSWhere], orderBy: FSOrder?, limit: Int?) async throws -> [T]
    func streamCollection<T: Decodable>(_ collectionPath: String, filters: [FSWhere], orderBy: FSOrder?, limit: Int?) -> AsyncThrowingStream<FSCollectionEvent<T>, Error>
}

protocol AuthServicing {
    func createAuthUser(email: String, password: String) async throws -> AuthDataResult
    func signInAuthUser(email: String, password: String) async throws
    func fetchAuthUser () async -> User?
    func signOutAuthUser() throws
    func deleteAuthUser() async throws
    func authStateStream() -> AsyncStream<String?>
}

protocol StorageServicing {
    func imagePath(_ imageId: String) -> StorageReference
    func getImageURL(path: String) async throws -> URL
    func saveImage(data: Data, userId: String) async throws -> (path: String, url: URL)
    func deleteImage(path: String) async throws
}

protocol UserRepository {
    func createUser(draft: DraftProfile) throws -> UserProfile
    func fetchProfile(userId: String) async throws -> UserProfile
    func updateUser(userId: String, values: [UserProfile.Field : Any]) async throws
    func userListener(userId: String) -> AsyncThrowingStream<UserProfile?, Error>
}

protocol EventsRepository {
    func createEvent(draft: EventDraft, user: UserProfile, profile: UserProfile) async throws
    func eventTracker(userId: String, now: Date) async throws -> (initial: [UserEventUpdate], updates: AsyncThrowingStream<UserEventUpdate, Error>)
    func updateStatus(eventId: String, to newStatus: EventStatus) async throws
    func fetchPendingSentInvites(userId: String) async throws -> [UserEvent]
    func deleteAllSentPendingInvites(userId: String) async throws
    func cancelEvent(eventId: String, cancelledById: String, blockedContext: BlockedContext) async throws
}

protocol ProfilesRepository {
    func profilesListener(userId: String) async throws -> (initial: [ProfileRec], updates: AsyncThrowingStream<UpdateShownProfiles, Error>)
    func updateProfileRec(userId: String, profileId: String, status: ProfileRec.Status) async throws
}

protocol ImageLoading {
    @discardableResult
    func loadProfileImages(_ profiles: [UserProfile]) async -> [UIImage]
    func fetchImage(for url: URL) async throws -> UIImage
    func removeImage(for url: URL)
    func fetchFirstImage(profile: UserProfile) async throws -> UIImage?
}

protocol ProfileLoading {
    func fromEvents(_ events: [UserEvent]) async throws -> [ProfileModel]
    func fromIds(_ ids: [String]) async throws -> [ProfileModel]
    func fromEvent(_ event: UserEvent) async throws -> ProfileModel
    func fromId(_ id: String) async throws -> ProfileModel
}

protocol DefaultsManaging {
    func createDraftProfile(user: User)
    func update<T>(_ keyPath: WritableKeyPath<DraftProfile, T>, to value: T)
    func deleteDefaults()
    func advanceOnboarding()
}
