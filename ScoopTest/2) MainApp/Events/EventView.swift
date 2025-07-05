//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//

import SwiftUI




struct EventView: View {
    
    let profileImage = Profile.sampleMatch.images[0]
    let name = "Meeting \(Profile.sampleMatch.name)"
    
    @State var showEventDetails: Bool = false
    
    var body: some View {
        
        
        ZStack {
            VStack(spacing: 48) {
                
                Text(name)
                    .font(.title(32, .semibold))
                
                imageView
                
                CountdownView()
                
                EventDetailSummaryView()
                    .font(.body(24, .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .lineSpacing(12)
            }
            detailsButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.horizontal, 24)
                .padding(.top, 24)
        }
        .sheet(isPresented: $showEventDetails) {
            EventDetailsView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EventView()
        .environment(AppState())
}


extension EventView {
    
    private var detailsButton: some View {
        
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.body(.regular))
                Text("Details")
            }
            .frame(width: 100, height: 30)
            .font(.body(14, .bold))
            .foregroundStyle(.black)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.background)
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 0.2))
            .onTapGesture {
                showEventDetails = true
            }
    }
    
    private var imageView: some View {
        
        Image(profileImage)
            .resizable()
            .scaledToFit()
            .clipShape(Circle())
            .frame(width: 200, height: 200)
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
        
    }
}
