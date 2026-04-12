//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondPopupContainer: View {
    
    @State var vm: RespondViewModel
    @Binding var showPopup: Bool

    @State var showInfo: Bool = false
    @State private var selectedTab = 0
    
    private let peek: CGFloat = 16
    private let spacing: CGFloat = 0
    
    var body: some View {
        ZStack {
            CustomScreenCover { showPopup = false }
            
            GeometryReader { proxy in
                let cardWidth = proxy.size.width
                let pageWidth = max(cardWidth - peek, 0)

                ScrollView(.horizontal) {
                    HStack(spacing: spacing) {
                        acceptInvitePage(cardWidth: cardWidth)
                            .frame(width: pageWidth, alignment: .leading)
                            .tag(0)

                        counterInvitePage(cardWidth: cardWidth)
                            .frame(width: pageWidth, alignment: .bottomLeading)
                            .tag(1)
                    }
                    .scrollTargetLayout()
                    .padding(.trailing, peek)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
            }
            .hideTabBar()
            .sheet(isPresented: $showInfo) {Text("Info Screen")}
        }
    }
}

extension RespondPopupContainer {
    
    private func acceptInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            RespondAcceptContainer(vm: vm)
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    let progress = 1 - min(abs(phase.value), 1)
                    let scale = CGFloat(0.5 + progress * 0.5)
                    return content.scaleEffect(scale, anchor: .trailing).offset(y: 12)
                }
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func counterInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            
            RespondTimeAndPlaceView(vm: vm, showInvite: $showPopup)
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    let progress = 1 - min(abs(phase.value), 1)
                    let scale = CGFloat(0.5 + progress * 0.5)
                    return content.scaleEffect(scale, anchor: .leading).offset(y: 32)
                }
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}


/*
 
 TabView(selection: $selectedTab) {
     acceptInvitePage
         .tag(0)
     counterInvitePage
         .tag(1)
 }
 .tabViewStyle(.page(indexDisplayMode: .never))
 .hideTabBar()

 */
