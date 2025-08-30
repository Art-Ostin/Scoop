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
    
    @Binding var selectedProfile: ProfileModel?
    @State var profileHolder: ProfileModel?
    
    var body: some View {
        
        VStack(spacing: 36) {
            if let url = URL(string: event.otherUserPhoto) {
                imageContainer(size: 150, url: url)
                    .onTapGesture {
                        if let profileHolder {
                            withAnimation(.easeInOut(duration: 0.27)) {
                                selectedProfile = profileHolder
                            }
                        }
                    }
            }
            
            Text(event.otherUserName)
            
            LargeClockView(targetTime: event.time) {}
            
            EventFormatter(event: event, isInvite: false)
                .padding(.horizontal, 32)
        }
        .task {
            guard
                let profile = try? await vm.userManager.fetchUser(userId: event.otherUserId),
                let firstImage = try? await vm.cacheManager.fetchFirstImage(profile: profile)
            else {return}
            profileHolder = ProfileModel(event: event, profile: profile, image: firstImage)
        }
        .tag(event.id)
        .frame(maxHeight: .infinity)
    }
}



//#Preview {
//    EventSlot()
//}
