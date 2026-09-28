//
//  Meetup Preferences.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/09/2026.
//

import Foundation

struct MeetupPreferences: Codable, Hashable {
    let preferredActivities: [String]
    let preferredDays: [String]
    let dreamDate: String
}
