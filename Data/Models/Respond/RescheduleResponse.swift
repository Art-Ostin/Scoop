//
//  RescheduleResponse.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import Foundation

struct RescheduleResponse {
    let eventId: String
    let userId: String
    let recipientId: String
    let oldTimes: ProposedTimes
    let newTimes: ProposedTimes
}
