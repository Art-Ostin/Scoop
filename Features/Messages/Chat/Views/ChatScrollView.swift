//
//  ChatScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatScrollView: View {
    @Bindable var vm: ChatViewModel
    let ui: ChatUIState
    var isFocused: FocusState<Bool>.Binding
    let isEvent: Bool
    let image: UIImage?
    private let keyboardCompensationPadding: CGFloat = 72

    @State private var isFirstAppear: Bool = true
    @State private var distanceFromBottom: CGFloat = 0
    @State private var containerHeight: CGFloat = 0
    @State private var compensateOnShrink: Bool = false
    @State private var isScrolling = false //A drag or deceleration in progress: the list is the user's, never followed

    @State private var scrollPosition = ScrollPosition(idType: String.self)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.xxs) {
                ChatEventView(event: vm.eventProfile.event)
                inviteNoteSection
                messageScrollSection
            }
        }

        //1. The background of the scroll View
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .scrollFadeIfAvailable(edge: .bottom)
        .scrollFadeIfAvailable(edge: .top)


//        .customScrollFade(height: 100, showFade: true, edge: .top)
        .background(Color.appCanvas)
        .contentMargins(.top, Spacing.xxxl, for: .scrollContent)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        //The bottom stays pinned while a send is in flight, so the sent row growing in moves the older rows up by
        //exactly its growth — no scroll request, nothing to clamp or drop — and while a draft sits in the field at the
        //floor. The anchor follows content growth only: the composer growing is an inset change, which the geometry
        //action below follows instead. Off otherwise, so a received message keeps its animated scroll rather than a jump.
        .defaultScrollAnchor(!ui.flights.isEmpty || (ui.atFloor && ui.hasDraft) ? .bottom : nil, for: .sizeChanges)

        //2. Functions to trigger with updates
        .task(id: vm.messages.count == 0) {await loadMessages()} //Scroll to bottom on launch and if flip to zero
        .onChange(of: vm.messages.count) {onMessageSend($0, $1)}
        .onChange(of: isFocused.wrappedValue) { keyboardFocused($1)} //If new keyboard is focused
        .onChange(of: ui.floorRequest) { //A multi-line send's composer collapsed: the list settles on its floor
            withAnimation(SendChoreography.shift) { scrollPosition.scrollTo(edge: .bottom) }
        }

        //3. Tracks scroll geometry — distance from bottom AND container shrinks (keyboard open).
        .onScrollGeometryChange(for: ScrollGeometry.self) { $0 } action: { _, geo in
            distanceFromBottom = geo.contentSize.height - geo.contentOffset.y - geo.containerSize.height
            //The distance to the list's true floor: 0 at rest at the bottom. The container already excludes both
            //insets, and the offset runs from −insetTop (sim-probed: content 990, offset 210, top 134, container 646)
            let previousDistance = ui.distanceFromFloor
            ui.distanceFromFloor = geo.contentSize.height - (geo.contentOffset.y + geo.contentInsets.top + geo.containerSize.height)
            //A draft that wraps grows the composer and raises the floor by a line, and the bottom anchor ignores inset
            //changes (sim-traced: offset held, distance 0 → 21 at the second line, so every multi-line send went unflown).
            //A list that sat at its floor follows it up: the last message stays in view and the send still flies.
            let followsFloor = ui.hasDraft && !isScrolling && !compensateOnShrink
                && previousDistance <= SendChoreography.floorSlop && ui.distanceFromFloor > SendChoreography.floorSlop
            //scrollTo(y:) runs from the content's top edge, contentOffset from −insetTop (sim-traced: asked for 239 + 21, landed at 126)
            if followsFloor { scrollPosition.scrollTo(y: geo.contentOffset.y + geo.contentInsets.top + ui.distanceFromFloor) }
            let atFloor = followsFloor || ui.distanceFromFloor <= SendChoreography.floorSlop
            if ui.atFloor != atFloor { ui.atFloor = atFloor }
            if ui.containerWidth != geo.containerSize.width { ui.containerWidth = geo.containerSize.width }
            #if DEBUG
            if !ui.flights.isEmpty { SendMotionLog.scroll(offset: geo.contentOffset.y, contentHeight: geo.contentSize.height) }
            #endif
            let shrinkage = containerHeight - geo.containerSize.height
            if compensateOnShrink, shrinkage > 0, ui.flights.isEmpty {
                let target = geo.contentOffset.y + shrinkage + keyboardCompensationPadding
                scrollPosition.scrollTo(point: CGPoint(x: 0, y: target))
            }
            containerHeight = geo.containerSize.height
        }

        .onScrollPhaseChange { _, phase in
            if isScrolling != phase.isScrolling { isScrolling = phase.isScrolling }
        }

        //4. attach scrollPosition to scroll view so can programmatically scroll
        .scrollPosition($scrollPosition, anchor: .bottom)
    }
}

extension ChatScrollView {

    //1. Views for the messages
    private var inviteNoteSection: some View {
        ForEach(vm.inviteNotes) { note in
            InviteNoteSection(ui: ui, note: note, image: image)
        }
    }

    private var messageScrollSection: some View {
        ForEach(vm.messages) { message in
            MessageSection(vm: vm, ui: ui, message: message, image: image)
        }
    }

    //2.loadMessages on appear
    private func loadMessages() async {
        guard isFirstAppear, !vm.messages.isEmpty || !vm.inviteNotes.isEmpty else { return }
        let waitsForMessages = vm.messages.isEmpty //A thread of notes alone still waits for the listener's first snapshot
        scrollToBottomEdge()
        try? await Task.sleep(for: .milliseconds(50))
        scrollToBottomEdge()
        isFirstAppear = waitsForMessages
    }
    //3. Logic for sending a message
    private func onMessageSend(_ old: Int, _ new: Int) {
        guard !isFirstAppear, new > old else { return }
        guard ui.phase(for: vm.messages.last?.id) == nil else { return } //A flown send: its row's growth moves the list
        let isOwnMessage = vm.messages.last?.authorId == vm.userId
        guard isOwnMessage || distanceFromBottom < 100 else { return } //scroll to bottom if new message received
        //After the new row has laid out: a scroll issued in the append's own update is clamped to the old content and dropped
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            scrollToBottomEdge(animated: true)
        }
    }

    //4. Logic for scrolling when is Focused
    private func keyboardFocused(_ focused: Bool) {
        guard focused else {
            compensateOnShrink = false
            return
        }
        if distanceFromBottom < 250 {
            Task { //fixes bug and data race
                try? await Task.sleep(for: .milliseconds(16))
                scrollToBottomEdge(animated: true)
            }
        } else {
            compensateOnShrink = true
        }
    }

    //5. Scrolling to bottom edge
    private func scrollToBottomEdge(animated: Bool = false) {
        withAnimation(animated ? .move : nil) {
            scrollPosition.scrollTo(edge: .bottom)
        }
    }
}

extension View {

    @ViewBuilder
    func scrollFadeIfAvailable (edge: Edge.Set) -> some View {
        if #available(iOS 26.0, *) {
            self
                .scrollEdgeEffectStyle(.soft, for: edge)
        } else {
            self
            .customScrollFade(height: 100, showFade: true, edge: .top)
        }
    }
}
