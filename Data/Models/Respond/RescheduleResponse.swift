//
//  RescheduleResponse.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import Foundation

//Countering an invite with different days. The invite being answered is carried whole, so the
//repo can retire it into the event's log without the caller unpacking it field by field.
struct RescheduleResponse {
    let oldEvent: UserEvent
    let userId: String
    let newTimes: ProposedTimes

    var eventId: String { oldEvent.id }
    //The retiring proposal was theirs, so they are who the new one goes to
    var recipientId: String { oldEvent.otherUserId }
}
