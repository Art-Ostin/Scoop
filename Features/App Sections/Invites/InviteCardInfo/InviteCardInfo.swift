//
//  InviteCardHowItWorks.swift
//  Scoop
//
//  Created by Art Ostin on 12/04/2026.
//

import SwiftUI

struct InviteCardInfo: View {

    let event: UserEvent
    let user: UserProfile
    
    @Binding var showQuickInvite: UserProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(DetailInfo.allCases, id: \.self) {detail in
                CardDetailSection(event: event, type: detail)
            }
        }
        .lineSpacing(4)
        .padding(.top, 14.25)
        .padding(.bottom, 2)//needs bit more padding than 'action' section.
        .overlay(alignment: .bottomTrailing) {
            cantMakeItButton
        }
    }
    
    
    private var cantMakeItButton: some View {
        Button {
            showQuickInvite = user
        } label: {
            Text("Can't make it?")
                .font(.body(12, .bold))
                .foregroundStyle((Color(red: 0.35, green: 0.35, blue: 0.35)))
                .kerning(0.5)
                .offset(y: 2.5)
        }
    }
}

private struct CardDetailSection: View {
    let event: UserEvent
    let type: DetailInfo
    
    var body: some View {
        HStack(spacing: 16) {
            Image(type.image)
            (
                Text("\(type.title(event)): ")
                    .font(.body(14, .bold))
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                +
                Text(type.message(event))
            )
        }
        .font(.footnote)
        .foregroundStyle(.gray)
        .lineLimit(3)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
