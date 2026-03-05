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
    
    
    
    var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    
                    LazyVStack(spacing: 4) {
                        
                        ClearRectangle(size: 24)
                        ForEach(vm.messages) {idx in
                            let chat = vm.messages[idx]
                            MessageSection(vm: vm, idx: idx, message: chat)
                        }
                        
                        ClearRectangle(size: 1).id(bottomID)
                    }
                }
                .frame(maxWidth: .infinity)
                .customScrollFade(height: 100, showFade: true)
                .scrollIndicators(.hidden)
                .onChange (of: isFocused) {
                    if isFocused { withAnimation(.easeInOut) {proxy.scrollTo(bottomID, anchor: .bottom)} }
                }
                .onAppear {proxy.scrollTo(bottomID, anchor: .bottom)}
                .background(Color(red: 0.96, green: 0.95, blue: 0.92).opacity(0.08))
                .background(
                    Color(red: 0.96, green: 0.95, blue: 0.92)
                        .opacity(0.08)
                        .ignoresSafeArea(.keyboard)
                )
    }
}

    
    
    
    
    
    
/*
 .onChange(of: isUserScrollingUp) { oldValue, newValue in
     if newValue && isFocused  {
         isFocused = false
         isUserScrollingUp = false
     }

 */

/*
 .onScrollGeometryChange(for: CGFloat.self) { geometry in
     geoe
     
     
     g.contentOffset.y
 }, action: { oldY, newY in
     let directionThreshold: CGFloat = 24
     let delta = newY - oldY
     guard abs(delta) > directionThreshold else { return }
     isUserScrollingUp = (delta < 0)
 })
}

 */
