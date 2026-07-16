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
    @Binding var showMessageScreen: Bool
    
    @State var scrollProgress: Double = 0
    @State private var messageHeight: CGFloat = 0
    
    
    //Local Properties
    @State var showInfoSheet = false
    
    var hasMessage: Bool { event.message?.isEmpty == false }

    private func parseName(_ placeName: String) -> String {
        placeName.split(whereSeparator: { $0.isWhitespace })
            .prefix(2)
            .joined(separator: " ")
    }
    
    private var messageLineCount: Int {
        guard messageHeight > 0 else { return 0 }
        let lineHeight = UIFont.systemFont(ofSize: 14).lineHeight
        return Int(((messageHeight + 6) / (lineHeight + 6)).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nameTitle
                .padding(.horizontal, Spacing.margin)
            scrollView
            warningLabel
                .padding(.horizontal, Spacing.margin)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
           typeButton
        }
        .padding(.top, 20)
        .sheet(isPresented: $showInfoSheet) {
            Text(event.type.longTitle)
                .presentationDetents([.medium])
        }
    }
}


//Components
extension ConfirmInviteScreen {
    
    private var nameTitle: some View {
        Text(name)
            .font(.title(24, .bold))
            .foregroundStyle(Color.textPrimary)
    }
    
    private var warningLabel: some View {
        HStack(spacing: Spacing.md){
            Image("ConfirmIcon")
            
            Text("Not showing may result in a blocked account")
                .font(.body(14, .regular))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fillGray.opacity(0.5), in: .rect(cornerRadius: CornerRadius.sm)) //Color.accent.opacity(0.04)
    }
    
    private var typeButton: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(event.type.emoji)
                .font(.body(15))
            
            HStack(spacing: 2) {
                Text(event.type == .drink ? "Drink" : (event.type == .socialMeet) ?  "Social Meet" : (event.type == .custom) ? "Custom" : "Double Date")
                    .font(.body(14, .bold))
                    .foregroundStyle(Color.textPrimary.mix(with: Color.accent, by: 0.2)) //Subtle Tint of accent
                    .kerning(-0.1)
                Image(systemName:"info.circle")
                    .font(.body(9, .regular))
                    .foregroundStyle(Color.textPlaceholder.mix(with: Color.accent, by: 0.1)) //Subtle Tint of accent
                    .offset(y: -3)
                    .offset(x: 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, event.type == .drink ? 6 : 8)
        .background(Color.accent.opacity(0.05).mix(with: Color.fillGray, by: 0.5), in: Capsule())
        .padding(.horizontal, 24)
        .shrinkPress {showInfoSheet = true}
        .offset(y: -1 - (event.type == .drink ? 0 : 1)) //aligns it vertically for some reason
        .scaleEffect(0.85, anchor: .trailing)
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
                .padding(.top, 1) //Subtle visual alignment (as type icon overlay makes it slightly closer)
            
            messageSection
                .padding(.horizontal, Spacing.margin)
                .containerRelativeFrame(.horizontal, alignment: .leading)
        }
        .overlay(alignment: .bottomTrailing) {
            PageIndicator(count: 2, progress: scrollProgress, dotSize: 5, activeWidth: 8)
                .scaleEffect(0.6, anchor: .bottom)
                .padding(.trailing, Spacing.lg)
                .padding(.bottom, 18)
        }
        .scrollClipDisabled()
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: true, isCardInvite: true)
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: false, isCardInvite: true)
    }
        
    private var timePlaceTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            lineSection(image: "EventClockIcon", text: timeSectionString)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .padding(.top, -Spacing.xxs)
            lineSection(image: "EventMapIcon", text: parseName(event.place?.name ?? ""))
                .shrinkPress {MapsRouter.openGoogleMaps(item: event.place?.mapItem, withDirections: false)}
        }
        .font(.body(17, .medium))
    }
    
    private func lineSection(image: String, text: String) ->  some View {
        HStack(spacing: Spacing.md) {
            Image(image)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.body(18, .medium))
        }
    }
    
    @ViewBuilder
    private var messageSection: some View {
        if hasMessage {
            Text(event.message ?? "" )
                .font(.system(size: 14, weight: .regular, design: .default))
                .italic()
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(6)
                .getHeight($messageHeight)
                .offset(y: messageLineCount == 3 ? -Spacing.xs : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottomTrailing) {
                    HStack(spacing: 2) {
                        Text("Edit")
                            .font(.body(12, .medium))
                        
                        Image("EditButtonBlack")
                            .scaleEffect(0.8, anchor: .top)
                    }
                    .shrinkPress {showMessageScreen = true}
                }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Improve your invite with a message")
                    .font(.body(13, .medium))
                    .foregroundStyle(Color.textSecondary)
                
                Text("Add a message")
                    .foregroundStyle(Color.textSecondary)
                    .font(.body(14, .regular))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.fillGray, in: .rect(cornerRadius: 12))
                    .shrinkPress {
                        showMessageScreen = true
                    }
            }
            .offset(y: -Spacing.xxs)
        }
    }
}

//Time Section
extension ConfirmInviteScreen {
    
    private var timeSectionString: String {
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
        
        return value
    }
    
    private func daySuffix(at index: Int, dayCount: Int) -> String {
        guard index < dayCount - 1 else {
            return ""
        }
        
        return index == dayCount - 2 ? " or " : ", "
    }
}
