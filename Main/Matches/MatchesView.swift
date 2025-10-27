//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI
import FirebaseFunctions


struct MatchesView: View {
    
    @Environment(\.appState) private var appState
    @State var scrollViewOffset: CGFloat = 0
    @State var vm: MatchesViewModel
    @State var showProfileView = false
    @State var image: UIImage?
    @State var showSettingsView = false
    init(vm: MatchesViewModel) { _vm = State(initialValue: vm)}
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.background
                ScrollView {
                    VStack(spacing: 36) {
                        VStack(spacing: 0) {
                            tabSection
                            TabTitle(page: .matches, offset: $scrollViewOffset)
                        }
                    }
                }
            }
            .onPreferenceChange(TitleOffsetsKey.self) {value in
                scrollViewOffset = value[.matches] ?? 0
            }
            .coordinateSpace(name: Page.matches)
            .ignoresSafeArea()
        }
        
        
        .sheet(isPresented: $showSettingsView) {
            SettingsView(vm: SettingsViewModel(authManager: vm.authManager, sessionManager: vm.s))
        }
        .task(id: vm.user) {  image = try? await vm.fetchFirstImage()}
    }
}

extension MatchesView {
    
    
    private var tabSection: some View {
        HStack(alignment: .top) {
            Image(systemName: "gear")
                .font(.body(20))
                .padding(6)
                .foregroundStyle(.black)
                .glassIfAvailable()
            
            Spacer()
            
            Image(uiImage: image ?? UIImage())
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 15)
            }
        .padding(.top, 48)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
    
    
    
    private var noMatchesView: some View {
        VStack(spacing: 32) {
            Image("DancingCats")

            Text("View your past Meet Ups Here")
                .font(.body(20))
        }
        .frame(maxHeight: .infinity)
    }
}



/*
 
    if vm.events.isEmpty {
         noMatchesView
     } else {
         VStack(spacing: 32) {
             Text("HEllo World")
             ForEach(vm.events) {profileModel in
                 Text(profileModel.event?.otherUserName ?? "There was no name")
             }
         }
     }
 
 */
