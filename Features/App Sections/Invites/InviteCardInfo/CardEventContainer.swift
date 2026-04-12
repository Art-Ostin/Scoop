//
//  CardInfoContainer.swift
//  Scoop
//
//  Created by Art Ostin on 12/04/2026.
//

import SwiftUI

struct CardEventContainer: View {
    
    @Bindable var vm: RespondViewModel
    @State var ui = RespondUIState()
    let name: String
    var event: UserEvent {vm.respondDraft.originalInvite.event}
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
                if ui.showMeetInfo {
                    InviteCardInfo(event: event)
                        .transition(.move(edge: .trailing))
                } else {
                    InviteCardEvent(vm: vm, ui: ui, name: name)
                        .transition(.move(edge: .leading))
                }
        }
        .padding(.top, RespondUIState.CardLayout.topPadding)
        .padding(.bottom, RespondUIState.CardLayout.bottomPadding)
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: ui.showMeetInfo)
    }
}

extension CardEventContainer {
    
    @ViewBuilder
    private var title: some View {
        let titleText = ui.showMeetInfo ? "Michael's Invite" : "\(name)'s Invite"
        
        HStack(alignment: .bottom, spacing: 12) {
            Text(titleText)
                .contentTransition(.interpolate)
                .font(.custom("SFProRounded-Bold", size: 20))
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if ui.showMeetInfo {
                eventButton
            } else {
                InviteRespondButton(type: vm.respondDraft.originalInvite.event.type, showInfo: $ui.showMeetInfo)
                    .scaleEffect(0.9, anchor: .trailing)
                    .fixedSize()
            }
        }
    }
    
    private var eventButton: some View {
        Button {
            ui.showMeetInfo.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.body(14, .bold))
                    .foregroundStyle(Color.appGreen)

                Text("Event")
                    .foregroundStyle(Color.appGreen)
                    .font(.custom("SFProRounded-Bold", size: 12))
            }
            .padding(4)
            .kerning(0.5)
            .padding(.horizontal, 6)
            .stroke(16, lineWidth: 1, color: Color.appGreen.opacity(0.2))
            .offset(y: -2)
        }
    }
}
