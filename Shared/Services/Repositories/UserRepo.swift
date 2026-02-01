//
//  ScoopTest
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
        try await fs.get(userPath(userId))
    }
    
    func updateUser(userId: String, values: [UserProfile.Field : Any]) async throws {
        var data: [String: Any] = [:]
        for (key, value) in values { data[key.rawValue] = value}
        try await fs.update(userPath(userId), fields: data)
    }
    
    func userListener(userId: String) -> AsyncThrowingStream<UserProfile?, Error> {
        fs.listenD(userPath(userId))
    }
}
