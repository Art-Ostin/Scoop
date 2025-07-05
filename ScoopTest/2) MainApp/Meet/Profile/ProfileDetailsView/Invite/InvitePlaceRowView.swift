//
//  InvitePlaceView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct InvitePlaceRowView: View {
    var body: some View {
        
        HStack {
            Text("Place")
                .font(.body(20, .bold))
            Spacer()
            Image("InvitePlace")
        }
        
        
    }
}

#Preview {
    InvitePlaceRowView()
}
