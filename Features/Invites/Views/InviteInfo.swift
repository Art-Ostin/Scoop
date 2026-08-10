//
//  InviteCardInfoPager.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct InviteInfo: View {
    
    let event: EventProfile
    
    @State private var scrollProgress: Double = 0
    
    var isEventSlot: Bool = false
    var body: some View {
        
        VStack(spacing: isEventSlot ? Spacing.xxl : 54) {
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

extension InviteInfo {
    
    private var scrollView: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            ForEach(ScrollSections.allCases, id: \.self) {section in
                scrollSection(for: section)
                    .containerRelativeFrame(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)//Page reports its wrapped height, so the greedy pager can't squeeze the copy
            }
        }
        .fixedSize(horizontal: false, vertical: true)//Pager keeps the tallest page's height instead of collapsing to what it's offered
    }
    
    
    private func scrollSection(for section: ScrollSections) -> some View {
        VStack(spacing: 32) {
            section.image(type: event.event.type)
                .resizable()
                .scaledToFit()
                .frame(width: isEventSlot ? 250 : 275, height: isEventSlot ? 250 : 275)
            
            VStack(spacing: Spacing.md) {
                Text(section.title(type: event.event.type))
                    .font(.body(17, .bold))

                Text(section.detailText(event: event.event))
                    .font(.body(16, .medium))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 42)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)//Takes every line it needs — no tail ellipsis
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
        case .firstRespond: "Respond"
        case .secondMeet: "Meet"
        case .thirdMessage: "Message"
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
