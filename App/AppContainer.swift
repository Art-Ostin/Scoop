//
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.

import SwiftUI

struct AppContainer: View {

    @Environment(AppDependencies.self) private var dep
    @Environment(AppRouter.self) private var router

    //Profiles present here, above the TabView, so the real tab bar sits behind
    //them — covered while open, revealed and dimmed during the zoom dismissal
    //(see ProfileOverlayPresenter in ProfileMorph.swift).
    @State private var profileOverlay = ProfileOverlayPresenter()

    var body: some View {
        @Bindable var router = router

        ZStack {
            Group {
                if #available(iOS 26.0, *) {
                    TabView(selection: $router.selectedTab) {
                        Tab("", image: icon(.meet), value: AppTab.meet) { meetView }
                        Tab("", image: icon(.invites),value: AppTab.invites) { invitesView }
                        Tab("", image: icon(.events),value: AppTab.events) { eventsView }
                        Tab("", image: icon(.pastEvents), value: AppTab.pastEvents) { pastEventsView }
                    }
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

            ProfileOverlayLayer(presenter: profileOverlay)
        }
        .overlay(alignment: .top) { InAppNotificationOverlay() }
        .environment(profileOverlay)
    }
}

extension AppContainer {

    private func icon(_ tab: AppTab) -> String {
        tab.nativeIcon(selected: router.selectedTab == tab)
    }

    private var meetView: some View {
        MeetContainer(vm: MeetViewModel(
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
        return EventsContainer(
            vm: EventsViewModel(session: dep.session, userRepo: dep.userRepo, defaults: dep.defaultsManager, eventRepo: dep.eventRepo, chatRepo: dep.chatRepo, imageLoader: dep.imageLoader),
            showMessageScreen: $router.showMessageScreen, path: $router.eventsPath
        )
    }

    private var pastEventsView: some View {
        @Bindable var router = router
        return MessagesContainer(
            vm: MessagesViewModel(s: dep.session, storageService: dep.storageService, defaults: dep.defaultsManager, authService: dep.authService, chatRepo: dep.chatRepo, userRepo: dep.userRepo, profilesRepo: dep.profilesRepo, eventsRepo: dep.eventRepo, imageLoader: dep.imageLoader), path: $router.pastEventPath
        )
    }
}
