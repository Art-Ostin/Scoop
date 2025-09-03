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

final class LiveFirestoreService {
    
    let db = Firestore.firestore()
    
    @discardableResult
    func set<T: Encodable> (_ path: String, value: T) throws -> String{
        let ref = db.document(path)
        try ref.setData(from: value)
        return ref.documentID
    }
    
    func add<T: Encodable> (_ path: String, value: T) throws {
        try db.collection(path).addDocument(from: value)
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
                            if change.type == .added {
                                continuation.yield(.added(id: id, data: model))
                            } else {
                                continuation.yield(.modified(id: id, data: model))
                            }
                        } catch {
                            print(error)
                        }
                    case .removed:
                        continue
                    }
                }
            }
        }
    }
}
