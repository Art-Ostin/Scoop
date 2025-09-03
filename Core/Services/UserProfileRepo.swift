//
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.


import Foundation




class UserManager {
    
    private let auth: AuthManaging
    let fs = LiveFirestoreService()
    
    init(auth: AuthManaging) { self.auth = auth }
    
    private func userPath(_ id: String) -> String { "users/\(id)" }
    
    func createUser(draft: DraftProfile) throws -> String {
        let profileUser = UserProfile(draft: draft)
        _ = try fs.set(userPath(profileUser.id), value: profileUser)
    }
    
    
    private func fetchProfile(userId: String) async throws -> UserProfile {
        try await firestore.get(userPath(userId))
    }
    
    
    
    
    
    

    
    
    private func userDocument(userId: String) -> DocumentReference { userCollection.document(userId)}
    
    func createUser (draft: DraftProfile) throws -> UserProfile {
        let profileUser = UserProfile(draft: draft)
        try userDocument(userId: profileUser.id).setData(from: profileUser)
        return profileUser
    }
    
    func updateUser(values: [UserProfile.Field : Any]) async throws {
        guard let uid = await auth.fetchAuthUser() else {return}
        var data: [String: Any] = [:]
        for (key, value) in values { data[key.rawValue] = value }
        try await userDocument(userId: uid).updateData(data)
    }
    
    func updateIdealMeet(_ idealMeet: IdealMeetUp) async throws{
        let encodedMeetUp = try Firestore.Encoder().encode(idealMeet)
        try await updateUser(values: [UserProfile.Field.idealMeetUp : encodedMeetUp])
    }
    
    func updateUserArray(field: UserProfile.Field, value: String, add: Bool) async throws {
        if add {
            try await updateUser(values: [field: FieldValue.arrayUnion([value])])
        } else {
            try await updateUser(values: [field: FieldValue.arrayRemove([value])])
        }
    }
    
    func fetchUser(userId: String) async throws -> UserProfile {
        try await userDocument(userId: userId).getDocument(as: UserProfile.self)
    }
    
    
    func userListener(userId: String) -> AsyncThrowingStream<UserProfile?, Error> {
        AsyncThrowingStream { continuation in
            let reg = userDocument(userId: userId).addSnapshotListener { snapshot, error in
                if let error { continuation.finish(throwing: error) ; return }
                guard let snap = snapshot else { return }
                guard snap.exists else { continuation.yield(nil); return }
                do {continuation.yield(try snap.data(as: UserProfile.self)) }
                catch { continuation.finish(throwing: error)}
            }
            continuation.onTermination = { _ in reg.remove()}
        }
    }
}
