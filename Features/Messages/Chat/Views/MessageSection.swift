//
//  MessageSection.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct MessageSection: View {

    @Bindable var vm: ChatViewModel
    let ui: ChatUIState
    let message: ChatMessage

    var body: some View {
        let flight = ui.flight(for: message.id)
        let phase = flight?.phase
        VStack(spacing: 0) {
            if vm.isNewDay(for: message) {
                ChatDayDivider(date: message.dateCreated ?? Date())
                    .padding(.bottom, Spacing.md) //Inside the divider's own transition, so a sent row grows it in whole
                    .transition(flight == nil ? slideIn : growth(ChatDayDivider.height + Spacing.md).combined(with: .opacity))
            }
            MessageBubbleView(
                chat: message,
                //A row a flight carries keeps its tail and run gap until the flight is torn down: the clone wears a
                //tail, and the row's growth already counts the gap. The regroup after rides the teardown's `.move`.
                nextIsNewAuthor: phase != nil || vm.isNextNewAuthor(for: message),
                isMyChat: vm.isMyChat(message),
                containerWidth: ui.containerWidth,
                //The clock until the server confirms, and never swapped mid-flight: the time blurs in once the bubble has landed
                showsTime: !vm.isPending(message) && (phase == nil || phase == .dissolving),
                onBodyFrame: phase == nil ? nil : { ui.reportBody(frame: $0, for: message.id) }
            )
            //A row a send flight is carrying stays a ghost until the clone lands on it
            .opacity(phase == .flying ? 0 : 1)
            .transition(flight.map { growth($0.rowHeight) } ?? slideIn)
        }
    }
}

extension MessageSection {

    private var slideIn: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    //A sent row grows into place on the send's shift curve (the list, bottom-anchored, moves up by exactly that growth)
    private func growth(_ height: CGFloat) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(active: RowGrowth(fraction: 0, height: height), identity: RowGrowth(fraction: 1, height: height)),
            removal: slideIn
        )
    }
}

//The insertion half of a sent row's transition: its layout height runs 0 → the resting height while the
//content inside stays at its natural size (top-aligned; the row is invisible until the flight lands).
private struct RowGrowth: ViewModifier, Animatable {
    var fraction: CGFloat
    let height: CGFloat

    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }

    func body(content: Content) -> some View {
        //The content keeps its own height while its slot grows: squeezed, a wrapped bubble lays out as one truncated
        //line and reports a shorter body, which moves the flight's landing mid-air
        content
            .fixedSize(horizontal: false, vertical: true)
            .frame(height: fraction < 1 ? height * max(0, fraction) : nil, alignment: .top)
    }
}
