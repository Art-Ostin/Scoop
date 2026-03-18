//
//  InviteRespondButtons.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct AcceptButton: View {
    
    @Bindable var vm: RespondViewModel
    var body: some View {
        Button {
            print("Hello World")
        } label: {
            Text("Accept")
                .foregroundStyle(Color.white)
                .font(.body(16, .bold))
                .padding(.horizontal, 36)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.appGreen)
                )
        }
    }
}

struct DeclineButton: View {
    
    @Bindable var vm: RespondViewModel
    
    var body: some View {
        Button {
            print("Hello World")
        } label: {
            Text("Decline")
                .font(.body(16, .bold))
                .foregroundStyle(Color(red: 0.36, green: 0.36, blue: 0.36))
                .padding(.horizontal, 36)
                .frame(height: 40)
                .stroke(16, lineWidth: 1.5, color: Color(red: 0.84, green: 0.84, blue: 0.84))
        }
    }
}

