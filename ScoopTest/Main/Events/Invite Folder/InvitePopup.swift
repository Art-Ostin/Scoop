//
//  InviteAcceptPopup.swift
//  ScoopTest
//
//  Created by Art Ostin on 14/08/2025.
//

import SwiftUI

struct InvitePopup: View {
    
    let vm: ProfileViewModel
    let image: UIImage
    let event: UserEvent
    var isMessage: Bool { event.message != nil }
    
    var body: some View {
        
        VStack(spacing: 32) {
            
            HStack {
                CirclePhoto(image: image)
                
                Text("Meet \(event.otherUserName ?? "")")
                    .font(.title(24, .bold))
            }
            
            vm.dep.eventManager.eventFormatter(event: event)

            
            ActionButton(text: "Accept", isInvite: true, cornerRadius: 12) { }
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.background, in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(Color.grayBackground, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.25), radius: 50, x: 0, y: 10)
        .overlay(alignment: .topTrailing) {
            NavButton(.cross)
                .padding(20) //32
        }
        .padding(.horizontal, 24)
    }
}



//VStack(spacing: isMessage ? 24 : 0) {
//    
//    Text(vm.dep.eventManager.formatTime(date: event.time))
//        .font(.body(22, .bold))
//        .multilineTextAlignment(.center)
//        .lineSpacing(12)
//    
//    if let message = event.message {
//        Text(message)
//            .font(.body(.italic))
//            .foregroundStyle(Color.grayText)
//    }
//}

//#Preview {
//    InvitePopup()
//}

//extension InvitePopup {
//    
//    private var noMessage: some View {
//        VStack(spacing: 32) {
//            Text("Meet Arthur")
//                .font(.title(24, .bold))
//            
//            Text("Tonight 21:30 (Feb 28th) House Party, Legless Arms ")
//                .font(.body(22, .bold))
//                .multilineTextAlignment(.center)
//                .lineSpacing(12)
//            
//            ActionButton(text: "Confirm Meet Up", isInvite: true, cornerRadius: 12) { }
//            
//        }
//    }
//    
//    private var withMessage: some View {
//
//        VStack(alignment: .leading, spacing: 32) {
//            
//            Text("Meet Arthur")
//                .font(.title(24, .bold))
//            
//            VStack(spacing: 24) {
//                Text("Tonight 21:30 (Feb 28th) House Party, Legless Arms ")
//                    .font(.body(22, .bold))
//                    .multilineTextAlignment(.leading)
//                    .lineSpacing(4)
//                
//                Text("If you’re down would love to go get poutine and chill in the Jean Meance Park tomorrow?")
//                    .font(.body(.italic))
//                    .foregroundStyle(Color.grayText)
//            }
//            ActionButton(text: "Confirm Meet Up", isInvite: true, cornerRadius: 12) { }
//                .frame(maxWidth: .infinity, alignment: .center)
//
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        
//    }
//}


