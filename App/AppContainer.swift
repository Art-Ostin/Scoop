//
//  Scoop
//
//  Created by Art Ostin on 11/06/2025.

import SwiftUI

@MainActor
struct AppContainer: View {

    @Environment(AppRouter.self) private var router

    //Tab-scoped state stays alive for the lifetime of the authenticated app container.
    @State private var meetVM: MeetViewModel
    @State private var invitesVM: InvitesViewModel
    @State private var eventsVM: EventsViewModel
    @State private var messagesVM: MessagesViewModel

    //Profiles present here, above the TabView, so the real tab bar stays behind them (see ProfileMorph.swift).
    @State private var profileOverlay = ProfileOverlayPresenter()
    //The quick-invite card presents at the root too, in its own overlay below the profile layer.
    @State private var inviteOverlay = InviteOverlayPresenter()

    init(dependencies dep: AppDependencies) {
        _meetVM = State(initialValue: MeetViewModel(
            session: dep.session,
            defaults: dep.defaultsManager,
            userRepo: dep.userRepo,
            profileRepo: dep.profilesRepo,
            eventRepo: dep.eventRepo,
            imageLoader: dep.imageLoader
        ))

        _invitesVM = State(initialValue: InvitesViewModel(
            session: dep.session,
            defaults: dep.defaultsManager,
            imageLoader: dep.imageLoader,
            eventRepo: dep.eventRepo
        ))

        _eventsVM = State(initialValue: EventsViewModel(
            session: dep.session,
            userRepo: dep.userRepo,
            defaults: dep.defaultsManager,
            eventRepo: dep.eventRepo,
            chatRepo: dep.chatRepo,
            imageLoader: dep.imageLoader
        ))

        _messagesVM = State(initialValue: MessagesViewModel(
            session: dep.session,
            storageService: dep.storageService,
            defaults: dep.defaultsManager,
            authService: dep.authService,
            chatRepo: dep.chatRepo,
            userRepo: dep.userRepo,
            profilesRepo: dep.profilesRepo,
            eventsRepo: dep.eventRepo,
            imageLoader: dep.imageLoader
        ))
    }

    var body: some View {
        @Bindable var router = router

        ZStack {
            TabView(selection: $router.selectedTab) {
                Tab("", image: icon(.meet), value: AppTab.meet) {
                    MeetContainer(vm: meetVM)
                }
                .accessibilityLabel("Meet")

                Tab("", image: icon(.invites), value: AppTab.invites) {
                    InvitesContainer(vm: invitesVM)
                }
                .accessibilityLabel("Invites")

                Tab("", image: icon(.events), value: AppTab.events) {
                    EventsContainer(
                        vm: eventsVM,
                        showMessageScreen: $router.showMessageScreen,
                        path: $router.eventsPath
                    )
                }
                .accessibilityLabel("Events")

                Tab("", image: icon(.messages), value: AppTab.messages) {
                    MessagesContainer(vm: messagesVM, path: $router.pastEventPath)
                }
                .accessibilityLabel("Messages")
            }

            InviteOverlayLayer(presenter: inviteOverlay)
            ProfileOverlayLayer(presenter: profileOverlay)
        }
        .overlay(alignment: .top) { InAppNotificationOverlay() }
        .environment(profileOverlay)
        .environment(inviteOverlay)
    }
}

extension AppContainer {

    private func icon(_ tab: AppTab) -> String {
        tab.tabIcon(selected: router.selectedTab == tab)
    }
}
