//
//  GiveEmailPage.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

 






struct GiveEmailPage: View {
    
    @State var email: String = ""
    
    private func signInWithEmailLink() {
        
    }
    
    
    
    
    var body: some View {
        
        NavigationStack {
            
            VStack {
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius (12)
                    .padding()
                
                Button {
                    
                    signInWithEmailLink()
                    
                } label: {
                    Text("Submit")
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding()
                        .foregroundStyle(.white)
                }
                Spacer()
                .navigationTitle(Text("Add Email"))
            }
            
        }
    }
}

#Preview {
    GiveEmailPage()
}
