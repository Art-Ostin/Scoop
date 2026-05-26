//
//  ParentContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.

import SwiftUI

struct AppContainer: View {

    @Environment(AppDependencies.self) private var dep
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        Group {
            if #available(iOS 26.0, *) {
                TabView(selection: $router.selectedTab) {
                    Tab("", image: router.selectedTab == .meet       ? "BlackLogo"       : "AppLogoBlack",  value: AppTab.meet)       { meetView }
                    Tab("", image: router.selectedTab == .invites    ? "TabLetterBlack"  : "TabLetterGray", value: AppTab.invites)    { invitesView }
                    Tab("", image: router.selectedTab == .events     ? "EventBlack"      : "EventIcon",     value: AppTab.events)     { eventsView }
                    Tab("", image: router.selectedTab == .pastEvents ? "BlackMessage"    : "MessageIcon",   value: AppTab.pastEvents) { pastEventsView }
                }
                .tint(.black)
            } else {
                CustomTabBarContainerView(selection: legacyTabBinding) {
                    meetView       .tabBarItem(.meet,    selection: legacyTabBinding)
                    invitesView    .tabBarItem(.invites, selection: legacyTabBinding)
                    eventsView     .tabBarItem(.events,  selection: legacyTabBinding)
                    pastEventsView .tabBarItem(.matches, selection: legacyTabBinding)
                }
            }
        }
        .overlay(alignment: .top) { InAppNotificationOverlay() }
    }

    private var legacyTabBinding: Binding<TabBarItem> {
        Binding(
            get: { router.selectedTab.legacy },
            set: { router.selectedTab = .init(legacy: $0) }
        )
    }
}

extension AppContainer {

    private var meetView: some View {
        MeetContainer(vm: InviteViewModel(
            s: dep.session, defaults: dep.defaultsManager,
            userRepo: dep.userRepo,
            profileRepo: dep.profilesRepo,
            eventRepo: dep.eventRepo,
            imageLoader: dep.imageLoader
        ))
    }

    private var invitesView: some View {
        NavigationStack {
            InvitesContainer(vm: InvitesViewModel(session: dep.session, defaults: dep.defaultsManager, imageLoader: dep.imageLoader, eventRepo: dep.eventRepo))
        }
    }

    private var eventsView: some View {
        @Bindable var router = router
        return EventsContainer(
            vm: EventViewModel(session: dep.session, userRepo: dep.userRepo, defaults: dep.defaultsManager, eventRepo: dep.eventRepo, chatRepo: dep.chatRepo, imageLoader: dep.imageLoader),
            showMessageScreen: $router.showMessageScreen
        )
    }

    private var pastEventsView: some View {
        @Bindable var router = router
        return MessagesContainer(
            vm: MessagesViewModel(s: dep.session, storageService: dep.storageService, defaults: dep.defaultsManager, authService: dep.authService, chatRepo: dep.chatRepo, userRepo: dep.userRepo, profilesRepo: dep.profilesRepo, eventsRepo: dep.eventRepo, imageLoader: dep.imageLoader),
            path: $router.pastEventsPath
        )
    }
}

// Bridge for the iOS<26 CustomTabBar branch. Delete with the legacy branch.
private extension AppTab {
    var legacy: TabBarItem {
        switch self {
        case .meet:       .meet
        case .invites:    .invites
        case .events:     .events
        case .pastEvents: .matches
        }
    }
    init(legacy: TabBarItem) {
        switch legacy {
        case .meet:    self = .meet
        case .invites: self = .invites
        case .events:  self = .events
        case .matches: self = .pastEvents
        }
    }
}
