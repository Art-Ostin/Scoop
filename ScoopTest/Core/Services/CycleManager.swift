//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import FirebaseFirestore

final class CycleManager {

    private var userManager: UserManager

    init(userManager: UserManager) {
        self.userManager = userManager
    }

    private let users = Firestore.firestore().collection("users")
    private func cyclesCollection(userId: String) -> CollectionReference {
        users.document(userId).collection("recommendation_cycles")
    }
    private func cycleDocument(userId: String, cycleId: String) -> DocumentReference {
        cyclesCollection(userId: userId).document(cycleId)
    }
    private func recommendationsCollection(userId: String, cycleId: String) -> CollectionReference {
        cycleDocument(userId: userId, cycleId: cycleId).collection("recommendations")
    }
    private func recommendationDocument(userId: String, cycleId: String, profileId: String) -> DocumentReference {
        recommendationsCollection(userId: userId, cycleId: cycleId).document(profileId)
    }

    func fetchCycle(userId: String, cycleId: String) async throws -> CycleModel {
        try await cycleDocument(userId: userId, cycleId: cycleId).getDocument(as: CycleModel.self)
    }
    func fetchRecommendationItem(userId: String, cycleId: String, profileId: String) async throws -> RecommendationItem {
        try await recommendationDocument(userId: userId, cycleId: cycleId, profileId: profileId).getDocument(as: RecommendationItem.self)
    }
    func fetchCycleProfiles(userId: String, cycleId: String) async throws -> [String] {
        try await recommendationsCollection(userId: userId, cycleId: cycleId)
            .whereField(RecommendationItem.CodingKeys.recommendationStatus.stringValue,
                        isEqualTo: RecommendationStatus.pending.rawValue)
            .getDocuments(as: RecommendationItem.self)
            .map(\.id)
    }

    func createCycle(userId: String) async throws {
        let addedCount = 4
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let autoRemoveAt = Calendar.current.date(byAdding: .day, value: 21, to: now)!

        let cycle = CycleModel(
            cycleStats: CycleStats(total: addedCount, invited: 0, accepted: 0, dismissed: 0, pending: addedCount),
            profilesAdded: addedCount,
            endsAt: Timestamp(date: endsAt),
            autoRemoveAt: Timestamp(date: autoRemoveAt)
        )

        let docRef = try cyclesCollection(userId: userId).addDocument(from: cycle)
        let id = docRef.documentID
        try await createRecommendedProfiles(userId: userId, cycleId: id)
        try await userManager.updateUser(values: [UserProfile.CodingKeys.activeCycleId: id])
    }

    private func createRecommendedProfiles(userId: String, cycleId: String) async throws {
        let snap = try await users.getDocuments()
        let ids = snap.documents.map(\.documentID).filter { $0 != userId }
        let selectedIds = Array(ids.shuffled().prefix(4))

        for id in selectedIds {
            let newItem = RecommendationItem(id: id, profileViews: 0, recommendationStatus: .pending)
            try recommendationsCollection(userId: userId, cycleId: cycleId).addDocument(from: newItem)
        }
    }

    func updateCycle(userId: String, cycleId: String, key: String, field: Any) {
        cycleDocument(userId: userId, cycleId: cycleId).updateData([key: field])
    }
    func updateRecommendationItem(userId: String, cycleId: String, profileId: String, key: String, field: Any) {
        recommendationDocument(userId: userId, cycleId: cycleId, profileId: profileId).updateData([key: field])
    }

    func checkCycleStatus(activeCycle: CycleModel?) async -> CycleStatus {
        guard let doc = activeCycle else { return .closed }
        if Date() > doc.endsAt.dateValue() {
            if doc.cycleStats.pending == 0 || Date() > doc.autoRemoveAt.dateValue() {
                return .closed
            } else {
                return .respond
            }
        }
        return .active
    }

    func inviteSent(userId: String, cycleId: String, profileId: String) {
        updateRecommendationItem(userId: userId, cycleId: cycleId, profileId: profileId,
                                 key: RecommendationItem.CodingKeys.recommendationStatus.stringValue,
                                 field: RecommendationStatus.invited.rawValue)
    }

    func deleteCycle(userId: String, cycleId: String) async throws {
        updateCycle(userId: userId, cycleId: cycleId,
                    key: CycleModel.CodingKeys.cycleStatus.stringValue,
                    field: CycleStatus.closed)
        try await userManager.updateUser(values: [UserProfile.CodingKeys.activeCycleId: FieldValue.delete()])
    }
}

