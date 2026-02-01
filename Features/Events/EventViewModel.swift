//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation
import SwiftUI
import MapKit
import FirebaseFirestore



@MainActor
@Observable class EventViewModel {
    
    let sessionManager: SessionManager
    let userRepo: UserRepository
    let eventRepo: EventsRepository
    let imageLoader: ImageLoading
    
    init(sessionManager: SessionManager, userRepo: UserRepository, eventRepo: EventsRepository, imageLoader: ImageLoading) {
        self.sessionManager = sessionManager
        self.userRepo = userRepo
        self.eventRepo = eventRepo
        self.imageLoader = imageLoader
    }

    var events: [ProfileModel] { sessionManager.events}
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await eventRepo.updateStatus(eventId: eventId, to: status)
    }
    
    func loadImages(profileModel: ProfileModel) async -> [UIImage] {
        return await imageLoader.loadProfileImages([profileModel.profile])
    }
    
    func cancelEvent(event: UserEvent) async throws {
        //Get the fields for the 'blockedContext'
        guard let acceptedTime = event.acceptedTime, let eventId = event.id else { return }
        let profileName = event.otherUserName
        let eventTime = "\(EventFormatting.expandedDate(acceptedTime)) · \(EventFormatting.hourTime(acceptedTime))"
        let eventPlace = event.place.name ?? event.place.address.map { String($0.suffix(10)) }  ?? ""
        let blockedContext = BlockedContext(profileImage: event.otherUserPhoto, profileName: profileName, eventPlace: eventPlace, eventTime: eventTime, eventMessage: event.message, eventType: event.type)
        let userId = sessionManager.user.id
        
        //Update event Status and the user
        try await applyCancellationPenalty(blockedContext: blockedContext, userId: userId)
        try await eventRepo.cancelEvent(eventId: eventId, cancelledById: userId, blockedContext: blockedContext)
    }
    
    private func applyCancellationPenalty(blockedContext: BlockedContext, userId: String) async throws {
        let encodedBlockedContext = try Firestore.Encoder().encode(blockedContext)
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        try await userRepo.updateUser(userId: userId, values: [.blockedContext : encodedBlockedContext] )
        try await userRepo.updateUser(userId: userId, values: [.frozenUntil : twoWeeksFromNow] )
        try await userRepo.updateUser(userId: userId, values: [.cancelCount: FieldValue.increment(Int64(1))])
    }
}

@Observable
final class EventUIState {
    var showEventDetails: UserEvent? = nil
    var showMessageScreen: ProfileModel? = nil
    var showCantMakeIt: ProfileModel? = nil
    var selectedProfile: ProfileModel? = nil
}

