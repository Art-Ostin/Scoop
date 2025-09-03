//
//  FirestoreService.swift
//  Scoop
//
//  Created by Art Ostin on 03/09/2025.
//

import Foundation
import FirebaseFirestore

enum FSChange<T> {
    case added(id: String?, data: T)
    case modified(id: String?, data: T)
}

final class LiveFirestoreService: FirestoreService {
    
    
    let db = Firestore.firestore()
    
    func set<T: Encodable> (_ path: String, value: T) throws {
        try db.document(path).setData(from: value)
    }
    
    func add<T: Encodable> (_ path: String, value: T) throws -> String {
        let ref = try db.collection(path).addDocument(from: value)
        return ref.documentID
    }
    
    func get<T: Decodable>(_ path: String) async throws -> T {
        return try await db.document(path).getDocument(as: T.self)
    }
    
    func update(_ path: String, fields: [String : Any])  {
        db.document(path).updateData(fields)
    }
    
    func listenD<T: Decodable>(_ path: String) -> AsyncThrowingStream<T?, Error> {
        AsyncThrowingStream { continuation in
            let reg = db.document(path).addSnapshotListener { snapshot, error in
                if let error { continuation.finish(throwing: error) ; return }
                guard let snap = snapshot else { return }
                guard snap.exists else { continuation.yield(nil); return }
                do {continuation.yield(try snap.data(as: T.self)) }
                catch { continuation.finish(throwing: error)}
            }
            continuation.onTermination = { _ in reg.remove()}
        }
    }
    
    func listenC<T: Decodable>(query: Query) -> AsyncThrowingStream<FSChange<T>, Error> {
        AsyncThrowingStream { continuation in
            let reg = query.addSnapshotListener { snapshot, error in
                if let error { continuation.finish(throwing: error) ; return }
                guard let snap = snapshot else { return }
                for change in snap.documentChanges {
                    switch change.type {
                    case .added, .modified:
                        do {
                            let model = try change.document.data(as: T.self), id = change.document.documentID
                            continuation.yield(change.type == .added ? .added(id: id, data: model) : .modified(id: id, data: model))
                        } catch { print(error) }
                    case .removed:
                        continue
                    }
                }
            }
        }
    }
}
