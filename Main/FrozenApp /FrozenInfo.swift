//
//  FrozenExplainedScreen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct FrozenExplainedScreen: View {
    
    //Turn this into a tab view. 
    
    let vm: FrozenViewModel
    let name: String
    let frozenUntilDate: Date
    let isBlocked: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            Text("Account" + (isBlocked ? "Blocked" : "Frozen"))
                .font(.body(24, .bold))
            
            VStack(alignment: .leading, spacing: 16) {
                if isBlocked {
                    Text("Your account is blocked as you didn't turn up to meet \(name)")
                } else {
                    Text("Your account is currently frozen as you cancelled on \(name).")
                    
                    Text("All Scoop functionality will be restored on \(EventFormatting.expandedDate(frozenUntilDate)).")
                }
            }
            .font(.body(17, .italic))
            .foregroundStyle(.black)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image("Clock")
                .resizable()
                .frame(width: 240, height: 240)
                .padding(.top, 48)
                .frame(maxWidth: .infinity, alignment: .center)
            
            
            OkDismissButton()
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
}
