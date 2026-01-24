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


struct FSWhere { let field: String; let op: FSOp; let value: Any }
enum FSOp { case eq, lt, lte, gt, gte }
struct FSOrder { let field: String; let descending: Bool }


final class LiveFirestoreService: FirestoreService {    
    
    let db = Firestore.firestore()
    
    func set<T: Encodable> (_ path: String, value: T) throws {
        try db.document(path).setData(from: value)
    }
    
    func add<T: Encodable> (_ path: String, value: T) throws -> String {
        let ref = try db.collection(path).addDocument(from: value)
        return ref.documentID
    }
    
    func increment(_ path: String, by deltas: [String: Int64]) {
        var payload: [String: Any] = [:]
        for (k, v) in deltas { payload[k] = FieldValue.increment(v) }
        db.document(path).updateData(payload)
    }
    
    func get<T: Decodable>(_ path: String) async throws -> T {
        return try await db.document(path).getDocument(as: T.self)
    }
    
    func update(_ path: String, fields: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.document(path).updateData(fields) { error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume() }
            }
        }
    }
    
    func delete(_ path: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.document(path).delete { error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume() }
            }
        }
    }
    
    
    func updateArray(_ path: String, append: [String: [Any]] = [:], remove: [String: [Any]] = [:]) async throws {
        var payload: [String: Any] = [:]
        for (k, v) in append where !v.isEmpty { payload[k] = FieldValue.arrayUnion(v) }
        for (k, v) in remove where !v.isEmpty { payload[k] = FieldValue.arrayRemove(v) }
        try await update(path, fields: payload)
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
    
    private func makeQuery(_ collectionPath: String, filters: [FSWhere], orderBy: FSOrder?, limit: Int?) -> Query {
        var q: Query = db.collection(collectionPath)
        for f in filters {
            switch f.op {
            case .eq:  q = q.whereField(f.field, isEqualTo: f.value)
            case .lt:  q = q.whereField(f.field, isLessThan: f.value)
            case .lte: q = q.whereField(f.field, isLessThanOrEqualTo: f.value)
            case .gt:  q = q.whereField(f.field, isGreaterThan: f.value)
            case .gte: q = q.whereField(f.field, isGreaterThanOrEqualTo: f.value)
            }
        }
        if let o = orderBy { q = q.order(by: o.field, descending: o.descending) }
        if let l = limit   { q = q.limit(to: l) }
        return q
    }
    
    func fetchFromCollection<T: Decodable>(_ collectionPath: String, filters: [FSWhere] = [], orderBy: FSOrder? = nil, limit: Int? = nil) async throws -> [T] {
        let q = makeQuery(collectionPath, filters: filters, orderBy: orderBy, limit: limit)
        let snap = try await q.getDocuments()
        return try snap.documents.map { try $0.data(as: T.self) }
    }
    
    func streamCollection<T: Decodable>(_ collectionPath: String, filters: [FSWhere], orderBy: FSOrder?, limit: Int?) -> AsyncThrowingStream<FSCollectionEvent<T>, Error> {
        return AsyncThrowingStream<FSCollectionEvent<T>, Error> { continuation in
            let q = makeQuery(collectionPath, filters: filters, orderBy: orderBy, limit: limit)
            
            var isFirst = true
            let reg = q.addSnapshotListener { snap, error in
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

