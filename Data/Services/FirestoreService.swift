//
//  FirestoreService.swift
//  Scoop
//
//  Created by Art Ostin on 03/09/2025.
//

import Foundation
import FirebaseFirestore


struct FSCollectionItem<Model> {
    let id: String
    let model: Model
}

enum FSCollectionEvent<Model> {
    case initial([FSCollectionItem<Model>])
    case added(FSCollectionItem<Model>)
    case modified(FSCollectionItem<Model>)
    case removed(id: String)
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
    
    
    
    func streamCollection<T: Decodable>(_ collectionPath: String) -> AsyncThrowingStream<FSCollectionEvent<T>, Error> {
        return AsyncThrowingStream<FSCollectionEvent<T>, Error> { continuation in
            var loadInitial = true
            let listener = db.collection(collectionPath).addSnapshotListener { snapshot, error in
                
                //1. Ensure data is correct and no errors
                if let error { continuation.finish(throwing: error) ; return }
                guard let snapshot else {return}
                
                do {
                    //2.If first time get all document matching the query, then yield it as initial
                    if loadInitial {
                        let items = try snapshot.documents.compactMap { doc in
                            FSCollectionItem(id: doc.documentID, model: try doc.data(as: T.self))
                        }
                        continuation.yield(.initial(items))
                        loadInitial = false
                        return
                    }
                    
                    //3.For any more updates to fields only get
                    for change in snapshot.documentChanges {
                        
                        //3.1. Construct the return Item - an ID and the data type (Need ID to e.g. construct profileModel from ID)
                        let doc = try change.document.data(as: T.self)
                        let newItem = FSCollectionItem(id: change.document.documentID, model: doc)
                        
                        //3.2. Return the value also communicating if the doc has been added, or removed, or modified
                        switch change.type {
                        case .added:
                            continuation.yield(.added(newItem))
                        case .modified:
                            continuation.yield(.modified(newItem))
                        case.removed:
                            continuation.yield(.removed(id: change.document.documentID))
                        }
                    }
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                listener.remove()
            }
            
        }
    }
}

/*
 func streamCollection<T: Decodable>(_ collectionPath: String, configure: (Query) -> Query = { $0 }) -> AsyncThrowingStream<T, Error> {
     let query = configure(db.collection(collectionPath))
     return AsyncThrowingStream<T, Error> { continuation in
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
 */

/*
 
 
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
}
 */
