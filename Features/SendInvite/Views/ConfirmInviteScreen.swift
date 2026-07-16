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
            
            Text("Not showing will result in your account being blocked")
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
            
            messageSection
                .padding(.horizontal, Spacing.margin)
                .containerRelativeFrame(.horizontal, alignment: .leading)
        }
        .overlay(alignment: .bottomTrailing) {
            AnimatedPageIndicator(count: 2, progress: scrollProgress, dotSize: 5, activeWidth: 8)
                .scaleEffect(0.6, anchor: .bottom)
                .padding(.trailing, Spacing.lg)
                .padding(.bottom, 18)
        }
        .scrollClipDisabled()
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: true, isCardInvite: true)
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: false, isCardInvite: true)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .overlay(alignment: .topTrailing) {
                    Image("EditButtonBlack")
                        .scaleEffect(0.8, anchor: .bottom)
                        .padding(6)
                        .padding(.top, Spacing.md)
                        .shrinkPress {
                            showMessageScreen = true
                        }
                        .padding(-6)
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
    
    private var timePlaceTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            typeAndPlace
                .padding(.top, -Spacing.xxs)
            timeSection
        }
        .font(.body(20, .medium))
    }
    
    private var typeAndPlace: some View {
        HStack(spacing: Spacing.xxs) {
            HStack(spacing: 0) {
                Text(parseName(event.place?.name ?? ""))
                    .underline(color: Color.border)
                    .italic()
                    .shrinkPress { MapsRouter.openGoogleMaps(item: event.place?.mapItem, withDirections: false)}
                Text(" · ")
                Text(event.type.longTitle)
            }
            .minimumScaleFactor(0.8)
            .lineLimit(1)

            Image(systemName: "info.circle")
                .foregroundStyle(Color.textPlaceholder)
                .font(.body(10, .regular))
                .padding(4)               // Enlarges the tap region
                .shrinkPress {
                    showInfoSheet = true
                }
                .padding(-4)              // Restores the original HStack layout
                .offset(y: -6)             // Moves both icon and tap region
        }
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
            .foregroundStyle(Color.primary)
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
