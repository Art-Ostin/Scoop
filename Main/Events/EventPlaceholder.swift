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
    
    let title = "Meeting"
        
    var body: some View {
        ZStack {
            Color.background
            ScrollView {
                VStack(alignment: .leading, spacing: 60) {
                    VStack {
                        TabButton(image: Image(systemName: "info.circle"))
                        TabTitle(page: .meeting, offset: $scrollViewOffset)
                    }
                    .padding(.horizontal, -24)

                    
                    
//                    TabTitle(page: .meeting, offset: $scrollViewOffset)

                    
                    Text("Upcoming Events appear Here")
                        .font(.title(16, .medium))
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Image("Plants")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 24) {
                        Text("Reload when you don't have to so that when you reload you don't have to")
                            .font(.body(16, .italic))
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)
                        
                        Text("-Oscar Wilde")
                            .font(.body(16, .bold))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    CustomDivider()
                    
                    VStack(spacing: 60) {
                        ImageSection(textTitle: "Social Meet", text: "Go to the same place that evening & meet each other & their friends", image: "EventCups")
                        CustomDivider()
                        ImageSection(textTitle: "Double Date ", text: "Both bring a friend along...social dating is the way", image: "DancingCats")
                        CustomDivider()
                        ImageSection(textTitle: "Grab a Drink ", text: "Invite them with a time and place, then meet up just the two of you", image: "CoolGuys")
                        CustomDivider()
                        ImageSection(textTitle: "Custom ", text: "Send a time and place with a message and do something out the ordinary", image: "Monkey")
                    }
                }
                .padding(.bottom, 240)
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 24)
            .overlay(alignment: .top) {
                ScrollNavBar(title: title)
                    .opacity(withAnimation { scrollViewOffset < 0 ? 1 : 0 } )
                    .ignoresSafeArea(edges: .all)
            }
            .onPreferenceChange(TitleOffsetsKey.self) { dict in
                scrollViewOffset = dict[.meeting] ?? 0
                print(scrollViewOffset)
            }
            .coordinateSpace(name: Page.meeting)
        }
        .ignoresSafeArea()
        .scrollIndicators(.hidden)

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


/*
 tabTitle
     .opacity(Double(scrollViewOffset) / 70)
     .background (
         GeometryReader { proxy in
             Color.clear.preference (
                 key: MeetingScrollViewOffset.self,
                 value: proxy.frame(in: .global).maxY
             )
         }
     )
 
 private var tabTitle: some View {
         HStack (spacing: 12) {
             Text(title)
                 .font(.tabTitle())
         }
         .frame(maxWidth: .infinity, alignment: .leading)
         .padding(.top, 96)
 }
 
 struct MeetingScrollViewOffset: PreferenceKey {
     static let defaultValue: CGFloat = 0
     
     static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
         value += nextValue()
     }
     
 }

 
 */



/*
 if !vm.events.isEmpty {
     EventView(vm: vm)
 } else {
     EventPlaceholder()
 }
 */
