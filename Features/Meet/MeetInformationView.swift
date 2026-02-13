//
//  MeetInformationView.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

//To expand when needed
struct MeetInfoView: View {
    
    @Bindable var vm: MeetViewModel
    
    @Bindable var ui: MeetUIState
    
    var body: some View {
        VStack(spacing: 60) {
            newProfileTimer
            DefaultAppButton(image: Image("PastInvites"), size: 25, isPresented: $ui.showPendingInvites)
        }
    }
}

extension MeetInfoView {
    
    private var newProfileTimer: some View {
        HStack(spacing: 0) {
            Text("new profiles in: ")
                .foregroundStyle(Color.grayText)
            SimpleClockView(targetTime: Calendar.current.date(byAdding: .day, value: 3, to: .now)!) {}
        }
        .font(.body(14))
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
}


struct PastInviteView: View {
    @Bindable var vm: MeetViewModel
    @Bindable var ui: MeetUIState

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 48) {
                    ForEach(vm.pendingInvites) { profileModel in
                        PendingInviteCard(
                            profile: profileModel,
                            showPendingInvites: $ui.showPendingInvites,
                            openPastInvites: $ui.openPastInvites
                        )
                    }
                }
            }
            .navigationTitle("Your Pending Invites")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
