//
//  EventDetailsHowItWorks.swift
//  Scoop Test
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

struct EventDetailsHowItWorks: View {

    let onBack: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTE")
                .font(.body(12, .medium))
                .foregroundStyle(Color(red: 0.51, green: 0.51, blue: 0.55))

            Text("No note added")
                .font(.body(17, .bold))

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            Button {
                onBack()
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color(red: 0.8, green: 0.8, blue: 0.8))
                    .font(.body(12, .medium))
            }
        }
        .modifier(DetailsBackground())
        .overlay(alignment: .topLeading) {
            Text("Message")
                .eventTextOverlay()
        }
    }
}

#Preview {
    EventDetailsHowItWorks(onBack: {})
}
