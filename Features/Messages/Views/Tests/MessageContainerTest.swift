//
//  MessageContainerTest.swift
//  Scoop Test
//
//  Created by Art Ostin on 04/06/2026.
//

import SwiftUI

enum MessagesScreen {
    case rootView, settings, profile
}

struct MatchedGeometryEffectTest: View {
    
    @State var showingScreen: MessagesScreen = .rootView
    
    @Namespace var settingsNS
    @Namespace var profileNS
    
    var body: some View {
        ZStack {
            switch showingScreen {
            case .rootView:
                rootView
            case .settings:
                settingsScreen
            case .profile:
                profileImageScreen
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingScreen)
    }

    private var settingsScreen: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(Color.orange)                          // the SAME shape, now full-screen
            .matchedGeometryEffect(id: "settings", in: settingsNS)
            .ignoresSafeArea()
            .overlay {                                   // content rides on top
                VStack(spacing: 24) {
                    ForEach(0..<10) { i in
                        Text("How it works \(i)")
                    }
                }
                .onTapGesture { showingScreen = .rootView }
            }
    }
    
    private var profileScreen: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(Color.blue)                          // the SAME shape, now full-screen
            .matchedGeometryEffect(id: "profile", in: profileNS)
            .ignoresSafeArea()
            .overlay {                                   // content rides on top
                VStack(spacing: 24) {
                    ForEach(0..<10) { i in
                        Text("How it works \(i)")
                    }
                }
                .onTapGesture { showingScreen = .rootView }
            }
    }
    
    private var profileImageScreen: some View {
        ZStack {
            Color.appCanvas.ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    VStack(spacing: 24) {
                        ForEach(0..<10) { i in
                            Text("How it works \(i)")
                        }
                    }
                    .onTapGesture { showingScreen = .rootView }
                }

            Image("Demo1")
                .matchedGeometryEffect(id: "profile", in: profileNS)
                .frame(width: 100, height: 100)
        }
    }
    
    private var rootView: some View {
        ZStack {
            NavigationStack {
                Color.appCanvas.ignoresSafeArea()
                    .navigationTitle("Messages")
            }
            MessagesHeader(showScreen: $showingScreen, settingsNS: settingsNS, profileNS: profileNS)
        }
    }
}
