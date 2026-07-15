//
//  ConfirmInviteScreen.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

struct ConfirmInviteScreen: View {
    
    //Injected Properties
    let name: String

    @Binding var event: EventFieldsDraft
    @Binding var showConfirmScreen: Bool
    
    @State var scrollProgress: Double = 0
    
    
    //Local Properties
    var hasMessage: Bool { event.message?.isEmpty == false }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nameTitle
                .padding(.horizontal, Spacing.margin)
            scrollView
            warningLabel
                .padding(.horizontal, Spacing.margin)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
}







//Components
extension ConfirmInviteScreen {
    
    private var nameTitle: some View {
        Text("Meet \(name)")
            .font(.title(24, .bold))
            .foregroundStyle(Color.textPrimary)
    }
    
    

    
    
    
    
    private var warningLabel: some View {
        HStack(spacing: Spacing.md){
            Image("ConfirmIcon")
            
            
            Text("Not showing will result in your account being blocked")
                .font(.body(14, .regular))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accent.opacity(0.04), in: .rect(cornerRadius: CornerRadius.sm))
    }
}

//ScrollView
extension ConfirmInviteScreen {
    
    private var scrollView: some View {
        PagerScrollView(peek: 0, progress: $scrollProgress) {
            timePlaceTypeSection
                .fixedSize(horizontal: false, vertical: true)   // pin single-line rows to natural height
                .padding(.horizontal, Spacing.margin)
                .padding(.vertical, 28)                 // pure hit-area; won't scale the type
                .containerRelativeFrame(.horizontal, alignment: .leading)

            if hasMessage {
                textView
                    .padding(.horizontal, Spacing.margin)
                    .containerRelativeFrame(.horizontal, alignment: .leading)
            }
        }
        .scrollClipDisabled()
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: true, isCardInvite: true)
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: false, isCardInvite: true)
    }
    
    
    
    private var textView: some View {
        Text(event.message ?? "" )
            .font(.system(size: 12, weight: .regular, design: .default))
            .italic()
            .foregroundStyle(Color.textSecondary)
    }
    
    
    private var timePlaceTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            typeAndPlace
                .padding(.top, -Spacing.hairline)
            timeSection
        }
    }
    
    
    private var typeAndPlace: some View {
        HStack(spacing: 0) {
            Text(event.place?.name ?? "")
            Text(" · ")
            
            HStack(alignment: .top, spacing: 3) {
                Text(event.type.longTitle)
                
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.textPlaceholder)
                    .font(.body(10, .regular))
                    .offset(y: -4)
            }
            .shrinkPress {
                print("hello")
            }
        }
        .font(.body(19, .medium))
        .minimumScaleFactor(0.8)
        .lineLimit(1)
    }
}

//Time Section
extension ConfirmInviteScreen {
    
    private var timeSection: some View {
        let days = event.time.availableDates()
        
        let value: String = {
            if days.count == 1, let day = days.first {
                return FormatEvent.dayAndTime(day)
            }
            return days.indices.map { index in
                let day = days[index]
                let isLast = index == days.count - 1
                
                return FormatEvent.shortDayAndTime(
                    day,
                    withHour: isLast
                ) + daySuffix(at: index, dayCount: days.count)
            }
            .joined()
        }()
        
        return Text(value)
            .font(.body(19, .medium))
            .foregroundStyle(Color.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
    }
    
    private func daySuffix(at index: Int, dayCount: Int) -> String {
        guard index < dayCount - 1 else {
            return ""
        }
        
        return index == dayCount - 2 ? " or " : ", "
    }

}


/*
 private var infoButton: some View {
     Image(systemName: "info.circle")
         .foregroundStyle(Color.textSecondary)
         .font(.body(12, .regular))
         .frame(width: 28, height: 28)
         .background(Color.fillGray, in: Circle())
         .padding(.horizontal, Spacing.lg)
         .expandHitArea()
         .profileShrinkPress {showConfirmScreen = false}
 }

 */
