//
//  EmailVerificationPage.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI

@Observable class





struct EmailVerificationView: View {
    
    @State var email = "arthur.ostin@mail.mcgill.ca"
    
    var body: some View {
        VStack {
            SignUpTitle(text: "Check Your Email")
            HStack {
                
                Text(verbatim: "arthur.ostin@mail.mcgill.com")
                    .foregroundStyle(Color.grayText)
                    .font(.body())
                
                Text(resend)
            }
        }
    }
}

#Preview {
    EmailVerificationPag()
}
