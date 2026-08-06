//
//  MeetPlaceholder.swift
//  Scoop Test
//
//  Created by Art Ostin on 11/07/2026.
//

import SwiftUI

// TEMPORARY DEBUG HARNESS (Claude, 2026-08-06): reproduces the send-invite
// screen without Firebase data so the TimeCustomMenu open/close can be
// frame-verified in the simulator against the device reference recording.
// TODO: revert to the plain "Hello World" placeholder before merge.
struct MeetPlaceholder: View {

    @State private var show = true
    @State private var vm = TimeAndPlaceViewModel(profileId: "debug-harness",
                                                  defaults: DefaultsManager())

    var body: some View {
        SendInviteContainer(
            images: [UIImage(named: "Demo1")].compactMap { $0 },
            name: "Jason",
            showInvite: $show,
            vm: vm,
            onSendInvite: { _ in },
            declineProfile: { }
        )
        .overlay(alignment: .topLeading) { simpleMenu }
    }

    /// A native-Menu-sized stand-in built from the SAME TimeCustomMenu — a
    /// square-ish five-row platter next to the tall When picker, so the
    /// open/close morphs can be judged on both aspect ratios side by side.
    /// Placed low so the platter blooms UPWARD like the reference recording.
    private var simpleMenu: some View {
        TimeCustomMenu(estimatedContentSize: CGSize(width: 250, height: 240),
                       placementOffsetX: 0, placementOffsetY: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<5) { i in
                    Text("HEllo World")
                        .font(.body(17, .regular))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 44)
                        .id(i)
                }
            }
            .padding(.horizontal, 16)
            .frame(width: 250)
        } label: {
            Text("Sun 9 Aug · 22:30")
                .font(.body(17, .medium))
                .foregroundStyle(.blue)
        }
        .padding(.leading, 48)
        .padding(.top, 660)
    }
}

#Preview {
    MeetPlaceholder()
}
