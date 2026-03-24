//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondPopupContainer: View {
    
    @State var vm: RespondViewModel
    @Binding var showPopup: Bool

    @State var showInfo: Bool = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            CustomScreenCover { showPopup = false }
            TabView(selection: $selectedTab) {
                acceptInvitePage
                    .tag(0)
                counterInvitePage
                    .tag(1)
            }
            .sheet(isPresented: $showInfo) {Text("Info Screen")}
            .tabViewStyle(.page(indexDisplayMode: .never))
            .hideTabBar()
        }
    }
}


extension RespondPopupContainer {
    
    private var acceptInvitePage: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            RespondAcceptContainer(vm: vm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var counterInvitePage: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            
            RespondTimeAndPlaceView(vm: vm, showInvite: $showPopup)
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

