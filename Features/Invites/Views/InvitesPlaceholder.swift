//
//  InvitesPlaceholder.swift
//  Scoop
//
//  Created by Art Ostin on 03/05/2026.
//

import SwiftUI

struct InvitesPlaceholder: View {
    var body: some View {
        CustomTabPage(page: .invites, tabAction: .constant(true)) {
            VStack(spacing: 96) {
                Text("Any invites received appear here")
                    .font(.title(20, .medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Image("CoolGuys")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(width: 250, height: 250)
            }
            .padding(.top, 72)            
        }
    }
}

#Preview {
    InvitesPlaceholder()
}
