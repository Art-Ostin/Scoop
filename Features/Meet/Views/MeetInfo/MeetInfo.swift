//
//  MeetInfo.swift
//  Scoop
//
//  Created by Art Ostin on 28/05/2026.
//

import SwiftUI

struct MeetInfo: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 48) {
                    ClearRectangle(size: 36)
                    MeetInfoCoverScrollView()
                    responseInfo
                        .padding(.horizontal, 24)
                    meetInfo
                        .padding(.horizontal, 24)
                    ClearRectangle(size: 48)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("How it Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { DismissToolbarItem(type: .cross) }
            .overlay(alignment: .bottom) {
                ActionButton(text: "Done") { dismiss() }
                    .padding(.bottom, 28)
            }
        }
    }
}

extension MeetInfo {

    private var responseInfo: some View {
        VStack(spacing: 36) {
            VStack(spacing: 24) {
                Text("2. Response")
                    .font(.title(24, .bold))

                
                Text("They can accept, decline, or propose a new time for you to respond to.")
                    .font(.body(18, .regular))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Image("CoolGuys")
        }
    }
    
    
    private var meetInfo: some View {
        VStack(spacing: 36) {
            VStack(spacing: 24) {
                Text("3. Meet")
                    .font(.title(24, .bold))
                
                Text("Once someone accepts, an event is created. Meet at the agreed time and place. You can message to help find each other.")
                    .font(.body(18, .regular))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Image("CoolGuys")
                .font(.body(15, .regular))
        }
    }
}

