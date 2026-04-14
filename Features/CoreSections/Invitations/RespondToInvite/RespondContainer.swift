//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondPopupContainer: View {
    
    @Binding var showPopup: Bool

    @State var vm: RespondViewModel
    @State var showTimePopup: Bool = false
    
    var body: some View {
        ZStack {
            CustomScreenCover { showPopup = false }
            GeometryReader { proxy in
                let cardWidth = proxy.size.width
                let pageWidth = max(cardWidth - 24, 0)

                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        acceptInvitePage(cardWidth: cardWidth)
                            .frame(width: pageWidth, alignment: .leading)
                            .tag(0)

                        counterInvitePage(cardWidth: cardWidth)
                            .frame(width: pageWidth + 4, alignment: .bottomLeading)
                            .tag(1)
                    }
                    .scrollTargetLayout()
                    .padding(.trailing, 16)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .onPreferenceChange(IsTimeOpen.self) { isTimeOpen in
                    showTimePopup = isTimeOpen
                }
            }
            .hideTabBar()
            .overlay(alignment: .top) {
                let dayCount = vm.respondDraft.newTime.proposedTimes.dates.count
                if vm.responseType == .modified {
                    SelectTimeMessage(type: vm.respondDraft.originalInvite.event.type, dayCount: dayCount, showTimePopup: showTimePopup)
                        .animation(.easeInOut(duration: 0.2), value: showTimePopup)
                }
            }
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
            
            
            RespondTimeAndPlaceView(vm: vm, showInvite: $showPopup) {eventDraft in}
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
