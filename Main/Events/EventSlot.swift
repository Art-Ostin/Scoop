//
//  EventSlot.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/08/2025.
//

import SwiftUI

struct EventSlot: View {

    let vm: EventViewModel
    @Binding var selectedProfile: ProfileModel?
    @State var profileModel: ProfileModel
    
    var body: some View {
        
        VStack(spacing: 60) {
            
            Text("You're Meeting\(profileModel.profile.name)")
                .font(.custom("SFProRounded-Medium", size: 24))
            
//            imageContainer(image: profileModel.image, size: 300)
//                .onTapGesture {
//                    selectedProfile = profileModel
//                }

            VStack(spacing: 48) {
                if let event = profileModel.event {
                    EventFormatter(time: event.time, type: event.type, message: event.message, isInvite: false, place: event.place)
                        .padding(.horizontal, 32)
                    
                    LargeClockView(targetTime: event.time) {}
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}



//#Preview {
//    EventSlot()
//}
