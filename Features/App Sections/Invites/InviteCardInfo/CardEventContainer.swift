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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            if ui.showMeetInfo {
                InviteCardHowItWorks()
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
    
    private var title: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text(ui.showMeetInfo ? "How It works" : "\(name)'s Invite")
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
                Image(systemName: "chevron.back")
                    .font(.body(17, .bold))
                
                Text("Event")
                    .foregroundStyle(Color.appGreen)
                    .font(.custom("SFProRounded-Bold", size: 12))
                    .padding(4)
                    .kerning(0.5)
                    .padding(.horizontal, 6)
                    .stroke(16, lineWidth: 1, color: Color.appGreen.opacity(0.2))
                    .offset(y: -2)
            }
        }
    }
}
