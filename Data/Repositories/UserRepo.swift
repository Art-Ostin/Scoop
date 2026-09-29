//
//  Scoop
//
//  Created by Art Ostin on 26/07/2025.


import Foundation

enum UpdateOp {
    case string(String)
    case append([String])
    case remove([String])
}

class UserRepo: UserRepository {
    
    private let fs: FirestoreService
    init(fs: FirestoreService ) {self.fs = fs }
    
    private func userPath(_ id: String) -> String { "users/\(id)" }
    
    func createUser(draft: DraftProfile) throws -> UserProfile {
        let profileUser = UserProfile(draft: draft)
        try fs.set(userPath(profileUser.id), value: profileUser)
        return profileUser
    }
    
    func fetchProfile(userId: String) async throws -> UserProfile {
        try await fs.getCacheFirst(userPath(userId))
    }
    
    //Acked, or queued (false) after 10 s: Firestore holds the write until it can land, so the caller may move on
    @discardableResult
    func updateUser(userId: String, values: [UserProfile.Field : Any]) async throws -> Bool {
        var data: [String: Any] = [:]
        for (key, value) in values { data[key.rawValue] = value}
        return try await fs.update(userPath(userId), fields: data, patience: 10)
    }
    
    func userListener(userId: String) -> AsyncThrowingStream<UserProfile?, Error> {
        fs.listenD(userPath(userId))
    }
}
