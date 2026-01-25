//
//  FrozenExplainedScreen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct FrozenExplainedScreen: View {
    
    //Turn this into a tab view. 
    
    
    @Environment(\.dismiss) private var dismiss
    let vm: FrozenViewModel
    let name: String
    let frozenUntilDate: Date
    
    
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 36) {
            Text("Account Frozen")
                .font(.body(24, .bold))
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Your account is currently frozen as you cancelled on \(name).")
                
                Text("All Scoop functionality will be restored on \(EventFormatting.expandedDate(frozenUntilDate)).")
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
            
            Button {
                dismiss()
            } label : {
                Text("OK")
                    .frame(width: 100, height: 40)
                    .foregroundStyle(Color.white)
                    .font(Font.body(17, .bold))
                    .background (
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color.accent)
                            .shadow(color: .black.opacity(0.12), radius: 2, y: 4)
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
}
