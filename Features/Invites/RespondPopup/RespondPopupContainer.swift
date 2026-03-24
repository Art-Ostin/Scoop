//
//  AcceptInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondPopupContainer: View {
    
    @Binding var showPopup: Bool
    
    @State var showInfo: Bool
    @State var tabSelection: Int
    @State var vm: RespondViewModel
    
    var body: some View {
        ZStack {
            CustomScreenCover { showPopup = false }
            TabView(selection: $tabSelection) {
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
    
    private func counterInvitePage(_ image: UIImage) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {showPopup = false}
            
            RespondTimeAndPlaceView(vm: vm, showInvite: $showPopup)
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

