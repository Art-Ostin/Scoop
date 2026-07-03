//
//  EventDetailsHowItWorks.swift
//  Scoop
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
                .foregroundStyle(Color.textSecondary)

            Text("No note added")
                .font(.body(17, .bold))

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            Button {
                onBack()
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.textPlaceholder)
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
