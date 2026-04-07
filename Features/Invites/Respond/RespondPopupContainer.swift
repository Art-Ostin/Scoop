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
    
    private let peek: CGFloat = 82
    private let spacing: CGFloat = 16
    
    var body: some View {
        ZStack {
            CustomScreenCover { showPopup = false }
            
            GeometryReader { proxy in
                let cardWidth = proxy.size.width - (peek * 2)

                ScrollView(.horizontal) {
                    HStack(spacing: spacing) {
                        acceptInvitePage
                            .frame(width: cardWidth)
                            .tag(0)

                        counterInvitePage
                            .frame(width: cardWidth)
                            .tag(1)
                    }
                    .scrollTargetLayout()
                    .frame(maxHeight: .infinity, alignment: .center)
                }
//                .safeAreaPadding(.horizontal, peek)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
            }
            .hideTabBar()
            .sheet(isPresented: $showInfo) {Text("Info Screen")}
        }
    }
}

extension RespondPopupContainer {
    
    private var acceptInvitePage: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            RespondAcceptContainer(vm: vm)
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    let progress = 1 - min(abs(phase.value), 1)
                    let scale = CGFloat(0.5 + progress * 0.5)
                    return content.scaleEffect(scale, anchor: .center)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var counterInvitePage: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            
            RespondTimeAndPlaceView(vm: vm, showInvite: $showPopup)
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    let progress = 1 - min(abs(phase.value), 1)
                    let scale = CGFloat(0.5 + progress * 0.5)

                    return content.scaleEffect(scale, anchor: .center)
                }
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
