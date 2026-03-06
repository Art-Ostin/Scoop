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
struct Identified<T> { let id: String; let model: T }

enum FSCollectionEvent<T> {
    case initial([Identified<T>])
    case added(Identified<T>)
    case modified(Identified<T>)
    case removed(String)
}


final class FirestoreService: FirestoreServicing {    
    
    let db = Firestore.firestore()
    
    //1. Functions to write to Firebase
    func set<T: Encodable> (_ path: String, value: T, merge: Bool = false) throws {
        try db.document(path).setData(from: value, merge: merge)
    }
    
    func add<T: Encodable> (_ path: String, value: T) throws -> String {
        let ref = try db.collection(path).addDocument(from: value)
        return ref.documentID
    }
    
    func update(_ path: String, fields: [String: Any]) async throws {
        try await db.document(path).updateData(fields)
    }
    
    func delete(_ path: String) async throws {
        try await db.document(path).delete()
    }
    
    //2. Functions to fetch from firebase
    func get<T: Decodable>(_ path: String) async throws -> T {
        return try await db.document(path).getDocument(as: T.self)
    }
    
    func fetchFromCollection<T: Decodable>(_ collectionPath: String, configure: (Query) -> Query = { $0 }) async throws -> [T] {
        let baseQuery = db.collection(collectionPath)
        let finalQuery = configure(baseQuery)
        let snap = try await finalQuery.getDocuments()
        return try snap.documents.map{ try $0.data(as: T.self)}
    }
    
    //3. Functions to listen to Firebase collections
    
//    func test<T: Decodable> (_ path: String, configure: (Query) -> Query = { $0 }) -> [T]? {
//        let baseQuery = db.collection(path)
//        let finalQuery = configure(baseQuery).addSnapshotListener { querySnapshot, error  in
//            if let error {
//                print (error)
//                return
//            }
//            
//            let items: [T] = []
//            
//            if let querySnapshot {
//                
//                for change in querySnapshot.documentChanges {
//                    
//                    switch change.type {
//                        
//                    case .added:
//                        if let item = try? change.document.data(as: T.self) {
//                            // Use `item` as needed, e.g., append to a local array or process it.
//                            // Currently, this function doesn't surface results; consider returning a stream or callback.
//                        }
//                        
//                    case .modified:
//                        
//                    case .removed:
//                        
//                    }
//                }
//            }
//        }
//        return nil
//    }
    
    
    
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
    
    
    func streamCollection<T: Decodable>(_ collectionPath: String, configure: (Query) -> Query = { $0 }) -> AsyncThrowingStream<FSCollectionEvent<T>, Error> {
        let query = configure(db.collection(collectionPath))
        return AsyncThrowingStream<FSCollectionEvent<T>, Error> { continuation in
            var isFirst = true
            let reg = query.addSnapshotListener { snap, error in
                if let err = error { continuation.finish(throwing: err); return }
                guard let snap else { return }
                
                if isFirst {
                    isFirst = false
                    let items: [Identified<T>] = snap.documents.compactMap {
                        guard let m = try? $0.data(as: T.self) else { return nil }
                        return Identified(id: $0.documentID, model: m)
                    }
                    continuation.yield(FSCollectionEvent<T>.initial(items))
                    return
                }
                for change in snap.documentChanges {
                    switch change.type {
                    case .added:
                        if let m = try? change.document.data(as: T.self) {
                            continuation.yield(.added(.init(id: change.document.documentID, model: m)))
                        }
                    case .modified:
                        if let m = try? change.document.data(as: T.self) {
                            continuation.yield(.modified(.init(id: change.document.documentID, model: m)))
                        }
                    case .removed:
                        break
                    }
                }
            }
            continuation.onTermination = { _ in reg.remove() }
        }
    }
}
