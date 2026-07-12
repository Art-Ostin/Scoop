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
                VStack(spacing: Spacing.xxl) {
                    MeetInfoCoverScrollView()
                    responseInfo
                    meetInfo
                }
            }
            .contentMargins(.top, Spacing.xl, for: .scrollContent)
            .contentMargins(.bottom, Spacing.titleGap, for: .scrollContent)
            .scrollIndicators(.hidden)
            .navigationTitle("How it Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { DismissToolbarItem(type: .cross) }
            .overlay(alignment: .bottom) {
                ActionButton(text: "Done") { dismiss() }
                    .padding(.bottom, Spacing.lg)
            }
        }
    }
}

extension MeetInfo {

    private var responseInfo: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                Text("2. Response")
                    .font(.title(24, .bold))

                
                Text("They can accept, decline, or propose a new time for you to respond to.")
                    .font(.body(18, .regular))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Image("CoolGuys")
        }
        .padding(.horizontal, Spacing.margin)
    }
    
    
    private var meetInfo: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
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
        .padding(.horizontal, Spacing.margin)
    }
}

