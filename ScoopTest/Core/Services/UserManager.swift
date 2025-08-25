//
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//



import Foundation
import FirebaseAuth
import FirebaseFirestore


class UserManager {
    
    private let auth: AuthManaging
    init(auth: AuthManaging) { self.auth = auth }
    
    private var userCollection: CollectionReference { Firestore.firestore().collection("users") }
    private func userDocument(userId: String) -> DocumentReference { userCollection.document(userId)}
        
    
    @discardableResult
    func createUser (draft: DraftProfile) async throws -> UserProfile {
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
}

