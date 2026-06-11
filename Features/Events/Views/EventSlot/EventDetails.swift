//
//  EventDetails.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/06/2026.


import SwiftUI

struct EventDetails: View {
    
    let type: Event.EventType
    let message: String?
    let time: Date
    let place: EventLocation

    let openMaps: () -> ()

    @State private var showBack = false

    var body: some View {
        ZStack(alignment: .top) {
            frontFace
                .opacity(showBack ? 0 : 1)
                .allowsHitTesting(!showBack)
                .zIndex(showBack ? 0 : 1)

            EventDetailsHowItWorks(onBack: { showBack = false })
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showBack ? 1 : 0)
                .allowsHitTesting(showBack)
                .zIndex(showBack ? 1 : 0)
        }
        .rotation3DEffect(.degrees(showBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut, value: showBack)
    }

    private var frontFace: some View {
        VStack(spacing: 18) {
            detailSection(title: "WHAT", mainText: type.longTitle, image: type.emoji, isType: true)
            divider
            detailSection(title: "WHEN", mainText: FormatEvent.dayAndTime(time), image: "EventClockIcon")
            divider
            detailSection(title: "WHERE", mainText: place.name ?? place.address ?? "Event Place?", image: "EventMapIcon")
        }
        .overlay(alignment: .topTrailing) {
            flipButton(toBack: true)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                openMaps()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.body(12))
                    Text("Maps")
                        .font(.body(10, .bold))
                }
                .foregroundStyle(Color(red: 0.55, green: 0, blue: 0.25))
            }
            .shrinkButton(shadow: .medium, shadowColor: .accent)
        }
        .modifier(DetailsBackground())
        .overlay(alignment: .topLeading) {
            detailsOverlay
        }
    }
}

extension EventDetails {
    
    private func detailSection(title: String, mainText: String, image: String, isType: Bool = false) -> some View {
        HStack(spacing: 24) {
            detailIcon(image: image, isType: isType)
            detailText(title: title, mainText: mainText)
            Spacer()//Pushes content to the left
        }
    }
    
    private func detailIcon(image: String, isType: Bool = false) -> some View {
        Group {
            if isType {
                Text(image)
                    .font(.body(18))
            } else {
                Image(image)
            }
        }
        .frame(width: 20, alignment: .leading)
    }
    
    @ViewBuilder
    private func detailText(title: String, mainText: String) -> some View {

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.body(12, .medium))
                    .foregroundStyle(Color(red: 0.77, green: 0.77, blue: 0.83))
                
                Text(mainText)
                    .font(.body(17, .bold))
            }
    }
    private var divider: some View {
        RoundedRectangle(cornerRadius: 10)
        .frame(maxWidth: .infinity, maxHeight: 1)
        .foregroundStyle(Color(white: 0.93))
    }
    
    private var detailsOverlay: some View {
        Text("Details")
            .eventTextOverlay(isDetails: true)
    }

    private func flipButton(toBack: Bool) -> some View {
        Button {
            showBack = toBack
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
                .font(.body(14, .medium))
        }
        .growButton()
    }
}

struct DetailsBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .eventCardShadowBackground()
    }
}


/*
 if title == "WHERE" {
     Button {
         openMaps()
     } label: {
         VStack(alignment: .leading, spacing: 8) {
             Text(title)
                 .font(.body(12, .medium))
                 .foregroundStyle(Color(red: 0.51, green: 0.51, blue: 0.55))
             
             Text(mainText)
                 .font(.body(17, .bold))
                 .foregroundStyle(Color(red: 0.55, green: 0, blue: 0.25))
         }
     }
 } else {

 */
