//
//  EventContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventPlaceholder: View {
    
    @Bindable var vm: EventViewModel
    @State private var scrollViewOffset: CGFloat = 0
    @State var showInfo: Bool = false
    let title = "Meeting"
        
    var body: some View {
        
        CustomTabPage(page: .Meeting, TabAction: $showInfo) {
            VStack(spacing: 84) {
                Text("Upcoming Events appear Here")
                    .font(.title(16, .medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Image("Plants")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                
                VStack(spacing: 24) {
                    Text(quotes.shared.allQuotes.randomElement()?.quoteText ?? "")
                        .font(.body(16, .italic))
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                    
                    Text("-\(quotes.shared.allQuotes.randomElement()?.name ?? "")")
                        .font(.body(16, .bold))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.bottom, 16)
            Divider()
            VStack(spacing: 60) {
                ImageSection(textTitle: "Social Meet", text: "Go to the same place that evening & meet each other & their friends", image: "EventCups")
                Divider()
                ImageSection(textTitle: "Double Date ", text: "Both bring a friend along...social dating is the way", image: "DancingCats")
                Divider()
                ImageSection(textTitle: "Grab a Drink ", text: "Invite them with a time and place, then meet up just the two of you", image: "CoolGuys")
                Divider()
                ImageSection(textTitle: "Custom ", text: "Send a time and place with a message and do something out the ordinary", image: "Monkey")
            }
        }
    }
}

struct ImageSection: View {
    let textTitle: String
    let text: String
    let image: String
    
    var body: some View {
        
        VStack(spacing: 36) {
            Text(textTitle)
                .font(.title(24, .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 24) {
                Image(image)
                    .resizable()
                    .frame(width: 240, height: 240)
                Text(text)
                    .font(.body(16, .medium))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(CGFloat(12))
            }
        }
    }
}
