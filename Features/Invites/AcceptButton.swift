//
//  AcceptButton.swift
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

