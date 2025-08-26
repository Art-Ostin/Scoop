//
//  SettingsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                VStack (alignment: .leading) {
                    Text (verbatim: "Arthur.ostin@mail.mcgill.ca")
                        .font(.body(16))
                        .foregroundStyle(Color.grayText)
                        .padding(.top, 24)
                        .offset(x: 44)
                        .offset(y: 12)
                    
                    customList(title: nil) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .padding(.bottom, 12)
                        softDivider
                            .padding(.trailing)
                        Text("Delete Account")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .padding(.top, 12)
                            .foregroundStyle(Color(red: 0.86, green: 0.21, blue: 0.27))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Settings")
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
        }
    }
    
    private var softDivider: some View {
        
        Rectangle()
            .frame(height: 1)
            .frame(maxWidth:.infinity)
            .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
            .padding(.leading, 24)
    }
    
    func customList<Content: View>(title: String?, @ViewBuilder content: () -> Content) -> some View {
        
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.grayText)
                    .padding(.horizontal, 24)
            }
            
            VStack(spacing: 6) {
                content()
            }
            .background(Color.white)
            .padding([.top, .bottom], 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 0.05)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
