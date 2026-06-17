//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {
    
    @Bindable var ui: TimeAndPlaceUIState
    
    @Binding var type: Event.EventType
    @Binding var unparsedMessage: String?
    
    @State private var messageHeight: CGFloat = 0

    var message: String  {
        (unparsedMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var lineCount: Int {
        guard !message.isEmpty, messageHeight > 0 else { return 0 }
        let lineHeight = UIFont.preferredFont(forTextStyle: .footnote).lineHeight
        return min(3, Int((messageHeight / lineHeight).rounded()))
    }

    var body: some View {
            HStack {
                inviteTypeText(.what)
                Spacer()
                inviteTypeButton
            }
            .padding(.top, typeTopPadding)
            .padding(.bottom, typeBottomPadding)
    }
}

//With Message Views
extension InviteTypeRow {
    
    @ViewBuilder
    private var inviteTypeButton: some View {
        CustomMenu {
            SelectTypeView(type: $type, showMessageScreen: $ui.showMessageScreen, showTypePopup: ui.binding(for: .type), message: message)
                .onAppear { ui.popupOpen = true }
                .onDisappear { ui.popupOpen = false }
        } label: {
            inviteTypeIcon
        }
    }
    
    private var inviteTypeIcon: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing) {
                
                Text( type.longTitle) //type.emoji + " " + Removed the Emoji
                    .font(.body(17, .medium))
                
                
                if !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .lineLimit(3)
                        .multilineTextAlignment(.trailing)
                    
                    //Measure the rendered height; lineCount is derived from it
                        .onGeometryChange(for: CGFloat.self) { geo in
                            geo.size.height
                        } action: { newValue in
                            messageHeight = newValue
                        }
                }
            }
            Image("InviteChevron")
        }
    }
    
    private var typeTopPadding: CGFloat {
        if lineCount == 0 {
            28
        } else if lineCount == 1 {
            24
        } else {
            20
        }
    }
    
    
    private var typeBottomPadding: CGFloat {
        if lineCount == 0 {
            28
        } else {
            14
        }
    }
}
