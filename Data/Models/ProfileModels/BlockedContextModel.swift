//
//  BlockedContextModel.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//
import Foundation

struct BlockedContext: Codable, Hashable {
    let profileImage: String
    let profileName: String
    let eventPlace: String
    let eventTime: String
    let eventMessage: String?
    let eventType: Event.EventType
}
