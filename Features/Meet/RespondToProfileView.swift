//
//  RespondToProfileView.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

struct RespondToProfileView: View {
    
    @Binding var showRespondToProfile: Bool?
    
    let isSent: Bool
    
    var body: some View {
        ZStack {
            if isSent {
                VStack(alignment: .center, spacing: 36) {
                    Image("CoolGuys")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    
                    Text("Invite Sent")
                        .font(.body(16, .bold))
                }
            } else {
                VStack(alignment: .center, spacing: 36) {
                    Image("Monkey")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    Text("Declined")
                        .font(.body(16, .bold))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .ignoresSafeArea()
        .zIndex(10)
        .transition(.opacity.animation(.easeInOut(duration: 0.18)))
        .background(Color.background)
//        .onAppear {
//            Task { @MainActor in
//                try? await Task.sleep(for: .seconds(1.2))
//                withAnimation(.easeInOut(duration: 0.2)) {
//                    showRespondToProfile = nil
//                }
//            }
//        }
    }
}

#Preview {
    RespondToProfileView(showRespondToProfile: .constant(true), isSent: true)
}
