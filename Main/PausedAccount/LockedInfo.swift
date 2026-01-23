//
//  LockedInfo.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct LockedInfo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            Text("Account Blocked")
                .font(.body(24, .bold))
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Your account was blocked for never showing to meet Arthur: ")
                
                
                
                
                
                Text("All Scoop functionality will be restored on Thursday 7th February.")
            }
            .font(.body(17, .italic))
            .foregroundStyle(.black)
            .lineSpacing(6)
        }
    }
}

#Preview {
    LockedInfo()
}
