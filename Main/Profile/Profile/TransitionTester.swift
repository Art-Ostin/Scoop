//
//  TransitionTester.swift
//  Scoop
//
//  Created by Art Ostin on 14/01/2026.
//

import SwiftUI

struct ContentView: View {
    @Namespace private var zoomNS

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Tap the image")
                    .font(.title2.bold())

                NavigationLink {
                    DetailView()
                        .navigationTransition(.zoom(sourceID: "testImage", in: zoomNS))
                        .toolbar(.hidden, for: .navigationBar)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jansj")
                            .font(.headline)
                        
                        Image("CoolGuys")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 500)
                            .matchedTransitionSource(id: "testImage", in: zoomNS)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
        }
        // This stays put across navigation and does NOT animate with the zoom.
        .overlay(alignment: .bottom) {
            Text("Hello World")
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 12)
        }
    }
}

struct DetailView: View {
    
    @State private var detailsOpen: Bool = true
    @State private var text = "Some Text below the image."
    @State private var didTriggerSwipeUp = false
    @State var infoOffset: CGFloat = 200
    
    @GestureState private var dragOffset = CGFloat.zero

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detail Screen")
                .font(.title.bold())

            Image("CoolGuys")
                .resizable()
                .scaledToFill()
                .frame(height: 360)
                .highPriorityGesture(swipeUpToChangeText, including: detailsOpen ? .all : .none)
                // Key change: simultaneous, not exclusive.
                .simultaneousGesture(swipeUpToChangeText)
            
                .highPriorityGesture(swipeUpToChangeText, including: detailsOpen ? .all : .none)

            Text(text)
                .offset(y: infoOffset)
            Spacer()
        }
        .padding()
        .overlay {
            if detailsOpen {
                Text("Details Open")
            }
        }
    }

    private var swipeUpToChangeText: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .updating($dragOffset) { value, state, _ in
                infoOffset = value.translation.height
            }
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                
                if value.translation.height > -75 {
                    detailsOpen.toggle()
                }
                // Only treat clearly-vertical drags as intentional.
                guard abs(dy) > abs(dx) else { return }

                // Upward swipe (negative dy).
                guard dy < -50 else { return }

                // Optional: fire once to avoid repeated toggles.
                guard !didTriggerSwipeUp else { return }
                didTriggerSwipeUp = true

                text = "Swiped Up Successfully"
            }
    }
}

#Preview {
    ContentView()
}
