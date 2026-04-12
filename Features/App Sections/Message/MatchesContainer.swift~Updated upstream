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
        CustomTabPage(page: .Matches, TabAction: $showSettingsView) {
            Text("Hello World")
        }
        .fullScreenCover(isPresented: $showSettingsView) {
            NavigationStack { SettingsView(vm: SettingsViewModel(authManager: vm.authManager, sessionManager: vm.s))}
        }
        .fullScreenCover(isPresented: $showProfileView) {
            NavigationStack {
                EditProfileContainer(vm: EditProfileViewModel(cacheManager: vm.cacheManager, s: vm.s, userManager: vm.userManager, storageManager: vm.storageManager))
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showProfileView = true
            } label: {
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 7, x: 0, y: 10)
                    .padding(.horizontal)
            }
        }
        .task(id: vm.user) {  image = try? await vm.fetchFirstImage()}
    }
}

extension MatchesView {
    
    private var tabSection: some View {
        HStack(alignment: .top) {
            TabButton(page: .Matches, isPresented: $showSettingsView)
            Spacer()
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
 
 ZStack {
     Color.background
     ScrollView {
         VStack(spacing: 36) {
             VStack(spacing: 14) {
                 tabSection
                 TabTitle(page: .Matches, offset: $scrollViewOffset)
             }
         }
     }
     .onPreferenceChange(TitleOffsetsKey.self) {value in
         scrollViewOffset = value[.Matches] ?? 0
     }
     .coordinateSpace(name: Page.Matches)
 }
 */
