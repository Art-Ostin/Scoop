//
//  EventSlot.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/08/2025.
//

import SwiftUI

struct EventSlot: View {
    
    
    let vm: EventViewModel
    let event: UserEvent
    
    @Binding var selectedProfile: UserProfile?
    @State var profileHolder: UserProfile?
    
    var body: some View {
        
        VStack(spacing: 36) {
            if let url = URL(string: event.otherUserPhoto ?? "") {
                imageContainer(size: 150, url: url)
                    .onTapGesture {
                        if let profileHolder {
                            withAnimation(.easeInOut(duration: 0.27)) {
                                selectedProfile = profileHolder
                            }
                        }
                    }
            }
            Text(event.otherUserName ?? "no name")
            
            if let time = event.time {
                LargeClockView(targetTime: time) {}
            }
            EventFormatter(event: event, isInvite: false)
                .padding(.horizontal, 32)
        }
        .task {
            profileHolder = try? await vm.dep.userManager.fetchUser(userId: event.otherUserId)
        }
        .tag(event.id)
        .frame(maxHeight: .infinity)
    }
}

//#Preview {
//    EventSlot()
//}
