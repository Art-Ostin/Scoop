//
//  SignUpPage.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

struct SignUpView: View {
    
    @State var selection: Int = 0
    @State var showOnboarding: Bool = false
    
    var body: some View {
            VStack(spacing: 60){
     
                titleSection
                
                tabViewSection
                
                ActionButton(text: "Login / Sign Up", onTap: {
                    showOnboarding.toggle()
                })
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                    EnterEmailView()
            }
    }
}

#Preview {
    SignUpView()
}

extension SignUpView {
    
    private var titleSection: some View {
        VStack(spacing: 24){
            Text("Scoop")
                .font(.title())
                .foregroundStyle(.black)

            Text("The McGill Dating App")
                .font(.body(18, .regular))
                .foregroundStyle(.black)

        }
    }
    
    private var tabViewSection: some View {
        TabView (selection: $selection) {
            
            Image("CoolGuys")
                .scaledToFit()
                .frame(width: 250, height: 250)
                .tag(0)
            
            VStack(spacing: 20) {
                Text("Two Profiles a day")
                Text("Best way to guage if you'll hit it of is to meet, so no texting")
                Text("Instead send time & place, & meet in person at a bar, party...")
            }
            .tag(1)
            .font(.body(18))
            .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .tabViewStyle(PageTabViewStyle())
    }
}
