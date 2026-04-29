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
    func set<T: Encodable> (_ path: String, value: T, merge: Bool) throws
    func add<T: Encodable> (_ path: String, value: T) throws -> String
    func get<T: Decodable>(_ path: String) async throws -> T
    func update(_ path: String, fields: [String : Any]) async throws
    func delete(_ path: String) async throws
    func encodeFields<T: Encodable>(_ value: T) throws -> [String: Any]
    func listenD<T: Decodable>(_ path: String) -> AsyncThrowingStream<T?, Error>
    func fetchFromCollection<T: Decodable>(_ collectionPath: String, configure: (Query) -> Query) async throws -> [T]
    func streamCollection<T: Decodable>(_ collectionPath: String, configure: (Query) -> Query) -> AsyncThrowingStream<FSCollectionEvent<T>, Error>
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
    func createEvent(draft: EventFieldsDraft, user: UserProfile, profile: UserProfile) async throws
    func eventTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<UserEvent>, Error>
    func updateEventStatus(eventId: String, to newStatus: Event.EventStatus) async throws
    func deleteAllSentPendingInvites(userId: String) async throws
    func cancelEvent(eventId: String, cancelledById: String, blockedContext: BlockedContext) async throws
    func updateRecentChat(message: MessageModel, eventId: String) async throws
    func readRecentMessages(userId: String, userEventId: String) async throws
    func acceptEvent(eventId: String, senderId: String, userId: String, acceptedTime: Date) async throws
    func declineEvent(eventId: String, otherUserId: String, userId: String) async throws
    func respondWithNewTime(newTime: RescheduleResponse) async throws
    func respondWithNewEvent(eventResponse: EventResponse) async throws
}

protocol ChatRepository {
    func sendMessage(text: String, eventId: String, userId: String, recipientId: String) async throws
    func fetchMessages(eventId: String) async throws -> [MessageModel]
    func chatsTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<ChatModel>, Error>
    func messagesTracker(eventId: String) -> AsyncThrowingStream<FSCollectionEvent<MessageModel>, Error>
}

protocol ProfilesRepository {
    func profilesTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<ProfileRec>, Error>
    func updateProfileRec(userId: String, profileId: String, status: ProfileRec.Status) async throws
}

protocol ImageLoading: Actor {
    func loadProfileImages(_ profile: UserProfile) async -> [UIImage]
    func fetchImage(for url: URL) async throws -> UIImage
    func removeImage(for url: URL)
    func fetchFirstImage(profile: UserProfile) async throws -> UIImage?
    func addProfileImagesToCache(for profiles: [UserProfile])
}

protocol ProfileLoading {
    func fromEvents(_ events: [UserEvent]) async throws -> [EventProfile]
    func fromIds(_ ids: [String]) async throws -> [PendingProfile]
}

protocol DefaultsManaging: AnyObject {
    var onboardingStep: Int { get }
    var signUpDraft: DraftProfile? { get }
    var recentMapSearches: [RecentPlace] { get }
    var preferredMapType: PreferredMapType? { get }
    var eventDrafts: [String: EventFieldsDraft] { get }
    var respondDrafts: [String: RespondDraft] { get }
    func createDraftProfile(user: User)
    func clearSignUpDraft()
    func mutateSignUpDraft(_ mutation: (inout DraftProfile) -> Void)
    func update<T>(_ keyPath: WritableKeyPath<DraftProfile, T>, to value: T)
    func deleteDefaults()
    func advanceOnboarding()
    func retreatOnboarding()
    func updateRespondDraft(eventId: String, respondDraft: RespondDraft)
    func fetchRespondDraft(eventId: String) -> RespondDraft?
    func deleteRespondDraft(eventId: String)
    func updateRecentMapSearches(title: String, town: String)
    func removeFromRecentMapSearches(place: RecentPlace)
    func updatePreferredMapType(mapType: PreferredMapType?)
    func updateEventDraft(profileId: String, eventDraft: EventFieldsDraft)
    func fetchEventDraft(profileId: String) -> EventFieldsDraft?
    func deleteEventDraft(profileId: String)
}
