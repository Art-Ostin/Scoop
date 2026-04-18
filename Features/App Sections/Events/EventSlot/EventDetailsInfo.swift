//
//  EventDetailsInfo.swift
//  Scoop
//
//  Created by Art Ostin on 17/04/2026.
//

import SwiftUI

struct EventDetailsInfo: View {
    let event: UserEvent
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    selectedTab = 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body(15, .bold))
                }
                
                Text("\(event.type.description.emoji)   \(event.type.longTitle)")
                    .font(.custom("SFProRounded-SemiBold", size: 18))
            }
            
            Text("Add Info Here")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
