//
//  ChatScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatScrollView: View {
    let bottomID = "bottomID"
    @Bindable var vm: ChatViewModel
    var isFocused: FocusState<Bool>.Binding
    let isEvent: Bool
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ClearRectangle(size: 72)
                    ChatEventView(event: vm.eventProfile.event)
                    messageScrollSection
                    ClearRectangle(size: 72).id(bottomID)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { scrollToBottom(proxy) }
            .background(Color.background)
            .onChange(of: vm.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .customScrollFade(height: 100, showFade: true)
            .scrollIndicators(.hidden)
            .onChange(of: isFocused.wrappedValue) { _, focused in
                if focused { scrollToBottom(proxy, animated: true) }
            }
            .onScrollGeometryChange(for: CGFloat.self) {scrollGeo in
                scrollGeo.contentOffset.y
            } action: {oldY, newY in
                //Get total contentOffset for swipe, if big enough swipe, dismiss keyboard.
                let totalMove = newY - oldY
                if totalMove < -30 {
                    isFocused.wrappedValue = false
                }
            }
            .id(vm.messages)
        }
    }
    
    private var messageScrollSection: some View {
        ForEach(vm.messages.indices, id: \.self) { idx in
            let messageModel  = vm.messages[idx]
            MessageSection(vm: vm, idx: idx, message: messageModel)
        }
    }
    
    
    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = false) {
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeInOut) { proxy.scrollTo(bottomID, anchor: .bottom) }
            } else {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }
}

/*
 .background(Color(red: 0.96, green: 0.95, blue: 0.92).opacity(0.08))
 .background(
     Color(red: 0.96, green: 0.95, blue: 0.5)
         .opacity(0.08)
         .ignoresSafeArea(.keyboard)
 )

 */
