//
//  SignUpPage.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

struct SignUpView: View {
    
    @State var selection: Int = 0
        
    @Environment(ScoopViewModel.self) var viewModel
    
    @State var showOnboarding: Bool = false

    
    var body: some View {
        
        
        VStack(spacing: 60){
 
            titleSection
            
            tabViewSection
            
            buttonSection
            
            
            .fullScreenCover(isPresented:$showOnboarding, content: { OnboardingContainerView() })
        }
    }
}

#Preview {
    SignUpView()
        .environment(ScoopViewModel())
}

extension SignUpView {
    
    private var titleSection: some View {
        VStack(spacing: 24){
            Text("Scoop")
                .font(.custom("NewYorkLarge-Bold", size: 32))
            Text("The McGill Dating App")
                .font(.custom("ModernEra-Regular", size: 18))
        }
    }
    
    private var tabViewSection: some View {
        TabView (selection: $selection) {
            Image("CoolGuys")
                .scaledToFit()
                .frame(width: 200, height: 200)
                .tag(0)
            
            VStack(spacing: 20) {
                Text("Two Profiles a day")
                Text("Send a Time and Place, No Texting!")
                Text("Go for a drink, House Party, Dinner, Double Date...")
            }
            .tag(1)
            .font(.custom("ModernEra-Regular", size: 18))
            .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .tabViewStyle(PageTabViewStyle())
    }
    
    private var buttonSection: some View {
        Button {
            showOnboarding = true
        } label: {
            Text("Login / Sign Up")
                .font(.custom("ModernEra-Bold", size: 18))
                .frame(width: 205, height: 42, alignment: .center)
                .background(Color(.tintColor), in: RoundedRectangle(cornerRadius: 33))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 2)
                .foregroundColor(.white)
        }
    }
    
}
