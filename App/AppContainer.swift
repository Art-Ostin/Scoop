//
//  ParentContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.

import SwiftUI

struct AppContainer: View {
    
    @State var tabSelection: TabBarItem = .meet
    @Environment(\.appDependencies) private var dep
        
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                TabView(selection: $tabSelection) {
                    meetView
                        .tag(TabBarItem.meet)
                        .tabItem {
                            Label("", image: tabSelection == .meet ? "BlackLogo" : "AppLogoBlack")
                        }
                    
                    invitesView
                        .tag(TabBarItem.invites)
                        .tabItem {
                            Label("", image: tabSelection == .invites ? "TabLetterBlack" : "TabLetterGray")
                        }
                    
                    eventsView
                        .tag(TabBarItem.events)
                        .tabItem {
                            Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")
                        }
                    
                    matchesView
                        .tag(TabBarItem.matches)
                        .tabItem {
                            Label("", image: tabSelection == .matches ? "BlackMessage" : "MessageIcon")
                        }
                }
                .tint(.black)
                .overlay(alignment: .top) {
                    notificationPopup
                }
            } else {
                CustomTabBarContainerView(selection: $tabSelection) {
                    meetView .tabBarItem(.meet, selection: $tabSelection)
                    invitesView .tabBarItem(.invites, selection: $tabSelection)
                    eventsView.tabBarItem(.events, selection: $tabSelection)
                    matchesView.tabBarItem(.matches, selection: $tabSelection)
                }
            }
        }
        .environment(\.tabSelection, $tabSelection)
    }
}

extension AppContainer {
    
    private var meetView: some View {
        MeetContainer(vm: InviteViewModel(
            s: dep.sessionManager, defaults: dep.defaultsManager,
            userRepo: dep.userRepo,
            profileRepo: dep.profilesRepo,
            eventRepo: dep.eventRepo,
            imageLoader: dep.imageLoader
        ))
    }
    
    private var invitesView: some View {
        InvitesContainer(vm: InvitesViewModel(session: dep.sessionManager, defaults: dep.defaultsManager, imageLoader: dep.imageLoader, eventRepo: dep.eventRepo))
    }
    
    private var eventsView: some View {
        EventsContainer(vm: EventViewModel(sessionManager: dep.sessionManager, userRepo: dep.userRepo, defaults: dep.defaultsManager, eventRepo: dep.eventRepo, chatRepo: dep.chatRepo, imageLoader: dep.imageLoader))
    }
    
    private var matchesView: some View {
        MessagesContainer(vm: MessagesViewModel(s: dep.sessionManager, storageService: dep.storageService, defaults: dep.defaultsManager, authService: dep.authService, chatRepo: dep.chatRepo, userRepo: dep.userRepo, profilesRepo: dep.profilesRepo, eventsRepo: dep.eventRepo, imageLoader: dep.imageLoader)
        )
    }
    
    private var notificationPopup: some View {
        
        HStack(spacing: 16) {
            //Use CirclePhoto after
            Image("Demo1")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Jane")
                    .font(.body(16, .bold))
                
                Text("Yes would love to go to the shop")
                    .font(.body(14, .regular))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2.5)
            }
        }
        .padding(.trailing, 16)
        .padding(.leading, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.background)
        )
        .padding(.horizontal, 16)
        .surfaceShadow(.floating, strength: 0.5)
    }
}

/*
 just say the day you're free and I am there and what is more this is an additional message to send to add a line
 */
