//
//  TestScreen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct BlockedContextView: View {
    
    let frozenContext: BlockedContext
    let vm: FrozenViewModel
    
    var body: some View {
        
        VStack(spacing: 6)  {
            
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 8) {
                    Image("ProfileMockB")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .clipShape(Circle())
                    
                    
                    Text("\(frozenContext.profileName)")
                        .font(.body(18, .bold))
                    
                    Spacer()
                    
                    Text("\(frozenContext.eventType.description.label)  \(frozenContext.eventType.description.emoji ?? "")")
                        .font(.body(14, .medium))
                        .offset(y: -10)
                        .offset(x: 6)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text(frozenContext.eventTime)
                    Text(frozenContext.eventPlace)
                }
                .foregroundStyle(Color(red: 0.32, green: 0.32, blue: 0.32))
                .font(.body(16, .regular))
            }
            .padding(22)
            .frame(width: 330, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color.background)
                    .shadow(color: .accent.opacity(0.15), radius: 4, y: 2)
            )
            .stroke(16, lineWidth: 1, color: Color.grayPlaceholder)
            .overlay(alignment: .bottomTrailing) {
                Text("\(vm.user.name) Cancelled")
                    .font(.body(12, .bold))
                    .foregroundStyle(.accent)
                    .padding()

            }
        }
    }
}

//#Preview {
//    TestScreen()
//}
