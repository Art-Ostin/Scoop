//
//  InviteImageHarness.swift
//  Scoop Test
//
//  Created by Art Ostin on 27/07/2026.
//

import SwiftUI




/*
 
 if ProcessInfo.processInfo.arguments.contains("-invite-animation-harness") {
     InviteAnimationHarness()
 } else {
 //Main App Went Here
 }
 
 @MainActor
 private struct InviteAnimationHarness: View {

     @State private var expanded = true
     @State private var vm: TimeAndPlaceViewModel
     private let image: UIImage

     init() {
         let image = UIImage(named: "Demo1")!
         let defaults = DefaultsManager(defaults: UserDefaults(suiteName: "InviteAnimationHarness")!)
         let profileId = "invite-animation-harness"
         let draft = EventFieldsDraft(
             time: ProposedTimes(items: [ProposedTime(date: Date().addingTimeInterval(86_400))]),
             place: EventLocation(mapItem: .mcGill)
         )
         defaults.updateEventDraft(profileId: profileId, eventDraft: draft)

         self.image = image
         _vm = State(initialValue: TimeAndPlaceViewModel(
             inviteModel: InviteContext(profileId: profileId, name: "Genevieve", image: image),
             defaults: defaults
         ))
     }

     var body: some View {
         SendInviteCard(
             vm: vm,
             image: image,
             images: [image],
             details: "Digital Artist · London",
             expanded: $expanded,
             sourceFrame: .zero,
             hideInvite: {},
             sendInvite: { _ in },
             declineProfile: {}
         )
     }
 }
 
 */
