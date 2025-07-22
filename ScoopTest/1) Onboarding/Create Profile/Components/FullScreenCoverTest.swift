//
//  FullScreenCoverTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/07/2025.
//

import SwiftUI

struct FullScreenCoverTest: View {
    
    @State private var showNext = false

    var body: some View {
        ZStack {
            
            Color.orange.ignoresSafeArea()
            
            Button("Show next screen") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showNext.toggle()
                }
            }

            if showNext {
                NextScreenTest()
                .transition(.move(edge: .bottom))
                .zIndex(1)
                .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showNext)
    }
}

struct NextScreenTest: View {
    
    @State var showNewScreen: Bool = false

    var body: some View {
        ZStack {
            Color(.blue)
            VStack(spacing: 20) {
                Text("Hello There")
                    .font(.largeTitle)
                Button("Go Back") {
                    withAnimation {
                        showNewScreen.toggle()
                    }
                }
            }
            if showNewScreen {
                ThirdScreenTest()
                    .ignoresSafeArea()
                    .transition(.move(edge: .top))
            }
        }
    }
}

#Preview {
    FullScreenCoverTest()
}


struct ThirdScreenTest: View {
    

    var body: some View {
        ZStack {
            Color(.purple)
            VStack(spacing: 20) {
                Text("Hello There")
                    .font(.largeTitle)
                Button("Go Back") {}
            }
        }
    }
}
