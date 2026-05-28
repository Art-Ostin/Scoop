//
//  MeetInfoCover.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/05/2026.
//

import SwiftUI

struct MeetInfoCover: View {
    
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "xmark")
                        .font(.body(12, .bold))
                }
            }
            .overlay(alignment: .bottom) {
                    ActionButton(isValid: true, text: "Done") { dismiss() }
                        .padding(.bottom, 28)
            }
            }
        }
    }

extension MeetInfoCover {

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

                
                Text("Once someone accepts, the event is created. Meet at the agreed time and place.")
                    .font(.body(18, .regular))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                
            }
            VStack(spacing: 24) {
                Image("CoolGuys")
                
                Text("*You can message once an event is accepted, to help find each other")
                    .font(.body(15, .regular))
                    .kerning(1.1)
            }
        }
    }
}

