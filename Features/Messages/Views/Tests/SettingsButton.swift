//
//  SettingsButton.swift
//  Scoop Test
//
//  Created by Art Ostin on 04/06/2026.
//

import SwiftUI

struct MessagesHeader: View {
    @Binding var showScreen: MessagesScreen

    let settingsNS: Namespace.ID
    let profileNS: Namespace.ID
    
    var body: some View {
        HStack {
            settingsButton
            Spacer()
            profileButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }
    
    private var profileButton: some View {
        Image("Demo1")
        .resizable()
        .scaledToFill()
        .clipShape(Circle())
        .buttonShadow(.high)
        .messageHeader(false, ns: profileNS) {showScreen = .profile}
    }
    
    private var settingsButton: some View {
        glassCircle
            .messageHeader(true, ns: settingsNS) {showScreen = .settings}
    }
        
    @ViewBuilder
    private var glassCircle: some View {
        if #available(iOS 26.0, *) {
            ZStack {
                Circle()
                    .fill(.clear)
                    .glassEffect(.regular.interactive(), in: Circle())
                
                Image(systemName: "gear")
                    .font(.body(16, .medium))
                    .foregroundStyle(.black)
            }
        } else {
            Circle()
                .fill(.ultraThinMaterial)
                .brightness(0.06)
                .buttonShadow(.customGlassShadow)
        }
    }
}

extension View {
    func messageHeader(_ isSettings: Bool, ns: Namespace.ID,  onTap: @escaping () -> ()) -> some View {
        self
            .matchedGeometryEffect(id: isSettings ? "settings" : "profile", in: ns)
            .frame(width: 35, height: 35)
            .contentShape(Circle())
            .growPress() { onTap() }
    }
}
