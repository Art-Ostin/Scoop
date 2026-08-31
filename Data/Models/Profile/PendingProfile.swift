//
//  ProfileInvite.swift
//  Scoop
//
//  Created by Art Ostin on 18/08/2025.
//
import Foundation
import UIKit

//User Facing Information about profiles
struct PendingProfile: Identifiable, Equatable, Hashable {
    let profile: UserProfile
    let image: UIImage
    var id: String { profile.id}
    
    static func == (lhs: PendingProfile, rhs: PendingProfile) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DeclinedProfile: Identifiable, Equatable, Hashable {
    let profile: PendingProfile
    let declinedAt: Date
    var id: String { profile.id }
}

extension DeclinedProfile {
    //The badge earns its place only once it's scarce, so above this the card wears nothing at all
    static let labelLead: TimeInterval = 2 * 24 * 60 * 60

    //When the window closes and this card drops out of History. Derived from the same constant
    //the filter uses, so the label and the removal can't drift apart.
    var expiresAt: Date { declinedAt.addingTimeInterval(Session.declinedWindow) }

    ///"2 days left" / "20 hours left" / "Under an hour" — nil while the card still has more than
    ///two days, which is most of its life. Ceil throughout: the number always reads as "gone
    ///within", so it never bottoms out at a zero, and each label lasts exactly its own unit.
    func timeLeft(asOf now: Date = .now) -> String? {
        let hour: TimeInterval = 60 * 60
        let day = 24 * hour
        let remaining = expiresAt.timeIntervalSince(now)

        guard remaining <= Self.labelLead else { return nil }
        //Also catches a lapsed card: it stays on screen until the next render prunes it
        guard remaining >= hour else { return "Under an hour" }

        if remaining > day {
            let days = Int((remaining / day).rounded(.up))
            return "\(days) day\(days == 1 ? "" : "s") left"
        }
        let hours = Int((remaining / hour).rounded(.up))
        return "\(hours) hour\(hours == 1 ? "" : "s") left"
    }
}
