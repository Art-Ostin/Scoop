//
//  InviteCardInfoPager.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct InviteCardInfoPager: View {
    
    let event: EventProfile
    
    @State private var scrollProgress: Double = 0
    
    var body: some View {
        
        VStack(spacing: 54) {
            Text("How It Goes")
                .font(.title(28))
                .foregroundStyle(Color.textPrimary)
            
            VStack(spacing: Spacing.lg) {
                scrollView
                
                PageIndicator(count: ScrollSections.allCases.count, progress: scrollProgress)
            }
        }
    }
}

extension InviteCardInfoPager {
    
    private var scrollView: some View {
        PagerScrollView(progress: $scrollProgress) {
            ForEach(ScrollSections.allCases, id: \.self) {section in
                scrollSection(for: section)
                    .containerRelativeFrame(.horizontal)
            }
        }
    }
    
    
    private func scrollSection(for section: ScrollSections) -> some View {
        VStack(spacing: 32) {
            section.image(type: event.event.type)
                .resizable()
                .scaledToFit()
                .frame(width: 275, height: 275)
            
            VStack(spacing: 16) {
                Text(section.title(type: event.event.type))
                    .font(.body(17, .bold))
                
                Text(section.detailText(event: event.event))
                    .font(.body(16, .medium))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 42)
                    .lineSpacing(6)
            }
        }
    }
}



enum ScrollSections: CaseIterable {
    
    case eventType, firstRespond, secondMeet, thirdMessage
    
    
    func image(type: Event.EventType) -> Image {
        switch self {
        case .eventType: Image("CoolGuys")
        case .firstRespond: Image("CoolGuys")
        case .secondMeet: Image("CoolGuys")
        case .thirdMessage: Image("CoolGuys")
        }
    }
    
    func title(type: Event.EventType) -> String {
        switch self {
        case .eventType: "\(type.longTitle)"
        case .firstRespond: "1. Respond"
        case .secondMeet: "2. Meet"
        case .thirdMessage: "3. Message"
        }
    }
    
    func detailText(event: UserEvent) -> String {
        switch self {
        case .eventType: 
            "\(event.type.howItWorks)"
        case .firstRespond:
            "\(event.type.howItWorksWithEvent(event))"
        case .secondMeet:
            "This is a placeholder to say that you will meet at x and y"
        case .thirdMessage:
            "After meeting you can exchange messages. But best get off this app... exchange numbers"
        }
    }
}

//It has distinctive image
