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
        
    var body: some View {
        VStack(spacing: 18) {
            detailSection(title: "WHAT", mainText: type.longTitle, image: type.emoji, isType: true)
            divider
            detailSection(title: "WHEN", mainText: FormatEvent.dayAndTime(time), image: "EventClockIcon")
            divider
            detailSection(title: "WHERE", mainText: place.name ?? place.address ?? "Event Place?", image: "EventMapIcon")
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
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.body(12, .medium))
                    .foregroundStyle(Color(red: 0.51, green: 0.51, blue: 0.55))
                
                Text(mainText)
                    .font(.body(17, .bold))
            }
        }
    }
    
    private var divider: some View {
        RoundedRectangle(cornerRadius: 10)
        .frame(maxWidth: .infinity, maxHeight: 1)
        .foregroundStyle(Color(white: 0.93))
    }
    
    
    private var detailsOverlay: some View {
        Text("Details")
            .eventTextOverlay()
    }
    
}

struct DetailsBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .stroke(16, lineWidth: 1, color:  Color.grayBackground)
            .eventCardShadowBackground()
    }
}
