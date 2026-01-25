//
//  LockedInfo.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct BlockedInfo: View {
    
    let blockedContext: BlockedContext
    let vm: FrozenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            Text("Account Blocked")
                .font(.body(24, .bold))
            
            Text("Your account is blocked for not showing to meet \(blockedContext.profileName)")
                .font(.body(17, .italic))
                .foregroundStyle(Color.grayText)
                .lineSpacing(6)
            
            BlockedContextView(frozenContext: blockedContext, vm: vm, isBlock: true)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
