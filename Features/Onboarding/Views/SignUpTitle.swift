//
//  SignUpTitle.swift
//  Scoop
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct SignUpTitle: View {
    
    //Injected
    let text: String
    var subtitle: String = ""

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            Text(text)
                .font(.title())
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }

            Text(subtitle)
                .font(.title(12, .medium))
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    SignUpTitle(text: "Hello", subtitle: "(Max 3)")
        .padding(.horizontal)
}
