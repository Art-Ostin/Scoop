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
                    Tab("", image: icon(.meet), value: AppTab.meet) { meetView }
                    Tab("", image: icon(.invites),value: AppTab.invites) { invitesView }
                    Tab("", image: icon(.events),value: AppTab.events) { eventsView }
                    Tab("", image: icon(.pastEvents), value: AppTab.pastEvents) { pastEventsView }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
            } else {
                CustomTabBarContainerView(selection: $router.selectedTab) { tab in
                    switch tab {
                    case .meet:       meetView
                    case .invites:    invitesView
                    case .events:     eventsView
                    case .pastEvents: pastEventsView
                    }
                }
            }
        }
        .overlay(alignment: .top) { InAppNotificationOverlay() }
    }
}

extension AppContainer {

    private func icon(_ tab: AppTab) -> String {
        tab.nativeIcon(selected: router.selectedTab == tab)
    }

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
        InvitesContainer(vm: InvitesViewModel(session: dep.session, defaults: dep.defaultsManager, imageLoader: dep.imageLoader, eventRepo: dep.eventRepo))
    }
    private var eventsView: some View {
        @Bindable var router = router
        return NavigationStack(path: $router.eventsPath) {
            EventsContainer(
                vm: EventViewModel(session: dep.session, userRepo: dep.userRepo, defaults: dep.defaultsManager, eventRepo: dep.eventRepo, chatRepo: dep.chatRepo, imageLoader: dep.imageLoader),
                showMessageScreen: $router.showMessageScreen, path: $router.eventsPath
            )
        }
    }

    private var pastEventsView: some View {
        @Bindable var router = router
        return NavigationStack(path: $router.pastEventPath) {
            MessagesContainer(
                vm: MessagesViewModel(s: dep.session, storageService: dep.storageService, defaults: dep.defaultsManager, authService: dep.authService, chatRepo: dep.chatRepo, userRepo: dep.userRepo, profilesRepo: dep.profilesRepo, eventsRepo: dep.eventRepo, imageLoader: dep.imageLoader), path: $router.pastEventPath
            )
            .hideTabBar(hideBar: !router.pastEventPath.isEmpty)
        }
    }
}
