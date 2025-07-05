//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI

struct MatchesView: View {
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 32) {
                Image("DancingCats")
                
                Text("View your past Meet Ups Here")
                    .font(.body(20))
                
            }
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 32) {
                        Image("GearIcon")
                        Image("Preferences")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                ToolbarItem {
                    ProfileButton
                }
            }
        }
    }
}


#Preview {
    MatchesView()
}

extension MatchesView {
    
    private var ProfileButton: some View {
        HStack (spacing: 18) {

            Image(Profile.sampleMe.images[0])
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)

        }
    }
}
