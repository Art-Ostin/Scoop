//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

enum RespondScrollType {
    case acceptPage, counterInvitePage
}

// The full-screen horizontal accept / counter-invite pager, with no backdrop or confirm
// alerts of its own so it can be dropped into the quick-invite morph as the card content
// (the morph supplies the backdrop and hosts the alerts). The accept card tags itself
// with `.morphCardAnchor()` so the morph surface grows into exactly that card.
struct RespondPager: View {

    @Bindable var vm: RespondViewModel
    @Bindable var ui: RespondPopupUIState
    @Binding var showPopup: Bool

    let onResponse: (ProfileResponse) -> Void

    // Measured bottom edge of the accept card (in the pager's coordinate space). The Hide
    // button pins to this so it sits just below the cards regardless of screen size, and
    // stays put while pages scroll horizontally (only X changes as they scroll, Y is stable).
    @State private var cardBottomY: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = proxy.size.width
            let pageWidth = max(cardWidth - 24, 0)

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    acceptInvitePage(cardWidth: cardWidth)
                        .frame(width: pageWidth, alignment: .leading)
                        .id(RespondScrollType.acceptPage)

                    counterInvitePage(cardWidth: cardWidth)
                        .frame(width: pageWidth + 4, alignment: .bottomLeading)
                        .id(RespondScrollType.counterInvitePage)
                }
                .opacity(ui.popupShown || ui.dismissHidePopup ? 0 : 1)
                .scrollTargetLayout()
                .padding(.trailing, 16)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $ui.scrollPosition)
            .onPreferenceChange(IsTimeOpen.self) {isTimeOpen in
                ui.showTimePopup = isTimeOpen
            }
        }
        .coordinateSpace(name: respondPagerSpace)
        .overlay(alignment: .top) { timeMessageOverlay }
        .overlay(alignment: .top) {
            HidePopup(onHide: { showPopup = false })
                .opacity(ui.popupShown || ui.dismissHidePopup || cardBottomY <= 1 ? 0 : 1)
                .offset(y: cardBottomY + 96)
        }
        .onPreferenceChange(RespondCardBottomKey.self) { cardBottomY = $0 }
    }
}

extension RespondPager {

    private func acceptInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
            RespondAcceptContainer(vm: vm, confirmNewTimeInvite: $ui.confirmNewTimeInvite, confirmAcceptInvite: $ui.confirmAcceptInvite) {
                onResponse(.decline)
            }
            .pageScrollTransition(anchor: .trailing, yOffset: 12)
            .background(cardBottomReader)
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func counterInvitePage(cardWidth: CGFloat) -> some View {
        ZStack {
            Color.clear
            RespondTimeAndPlaceView(vm: vm) { onResponse(.newInvite)}
                .pageScrollTransition(anchor: .leading, yOffset: 32)
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var timeMessageOverlay: some View {
        let dayCount = vm.respondDraft.newTime.proposedTimes.dates.count
        if vm.responseType == .modified {
            SelectTimeMessage(type: vm.respondDraft.originalInvite.event.type, dayCount: dayCount, showTimePopup: ui.showTimePopup)
        }
    }

    private var cardBottomReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: RespondCardBottomKey.self,
                value: proxy.frame(in: .named(respondPagerSpace)).maxY
            )
        }
    }
}

private let respondPagerSpace = "respondPager"

private struct RespondCardBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// The three confirm alerts for the respond flow. Hosted as a full-screen sibling of the
// pager (its own modifier) so its dim covers the whole screen rather than being clamped
// to the morph card frame.
struct RespondConfirmAlerts: ViewModifier {
    @Bindable var ui: RespondPopupUIState
    let onResponse: (ProfileResponse) -> Void

    func body(content: Content) -> some View {
        content
            .respondCustomAlert(isPresented: $ui.confirmNewTimeInvite, type: .sendNewTimes) { ui.dismissHidePopup = true ; onResponse(.newTime)}
            .respondCustomAlert(isPresented: $ui.confirmAcceptInvite, type: .acceptInvite) { ui.dismissHidePopup = true ; onResponse(.accepted)}
    }
}

extension View {
    func respondConfirmAlerts(ui: RespondPopupUIState, onResponse: @escaping (ProfileResponse) -> Void) -> some View {
        modifier(RespondConfirmAlerts(ui: ui, onResponse: onResponse))
    }
}

private extension View {
    func pageScrollTransition(anchor: UnitPoint, yOffset: CGFloat) -> some View {
        scrollTransition(.interactive, axis: .horizontal) { content, phase in
            let progress = 1 - min(abs(phase.value), 1)
            let scale = CGFloat(0.5 + progress * 0.5)
            return content.scaleEffect(scale, anchor: anchor).offset(y: yOffset)
        }
    }
}
