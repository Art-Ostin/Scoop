//
//  ParentContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.

import SwiftUI

struct AppContainer: View {

    @State var tabSelection: TabBarItem = .meet
    @State var matchesPath = NavigationPath()
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
                .overlay(alignment: .top) {messagePopupOverlay }
            } else {
                CustomTabBarContainerView(selection: $tabSelection) {
                    meetView .tabBarItem(.meet, selection: $tabSelection)
                    invitesView .tabBarItem(.invites, selection: $tabSelection)
                    eventsView.tabBarItem(.events, selection: $tabSelection)
                    matchesView.tabBarItem(.matches, selection: $tabSelection)
                }
                .overlay(alignment: .top) {messagePopupOverlay}
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
        NavigationStack {
            InvitesContainer(vm: InvitesViewModel(session: dep.sessionManager, defaults: dep.defaultsManager, imageLoader: dep.imageLoader, eventRepo: dep.eventRepo))
        }
    }
    
    private var eventsView: some View {
            EventsContainer(vm: EventViewModel(sessionManager: dep.sessionManager, userRepo: dep.userRepo, defaults: dep.defaultsManager, eventRepo: dep.eventRepo, chatRepo: dep.chatRepo, imageLoader: dep.imageLoader))
    }
    
    private var matchesView: some View {
        MessagesContainer(vm: MessagesViewModel(s: dep.sessionManager, storageService: dep.storageService, defaults: dep.defaultsManager, authService: dep.authService, chatRepo: dep.chatRepo, userRepo: dep.userRepo, profilesRepo: dep.profilesRepo, eventsRepo: dep.eventRepo, imageLoader: dep.imageLoader),
                          path: $matchesPath
        )
    }
    
    
    private var messagePopupOverlay: some View {
        MessagePopupView(
            model: dep.sessionManager.recentMessageReceived,
            imageLoader: dep.imageLoader,
            onTap: handlePopupTap,
            onDismiss: { dep.sessionManager.recentMessageReceived = nil }
        )
        .animation(.spring(duration: 0.4), value: dep.sessionManager.recentMessageReceived)
    }

    private func handlePopupTap(_ popup: MessagePopupModel) {
        let s = dep.sessionManager
        let candidates = s.pastEvents + s.events + s.invites
        guard let eventProfile = candidates.first(where: { $0.id == popup.eventId }) else { return }
        s.recentMessageReceived = nil
        tabSelection = .meet
        matchesPath.append(eventProfile)
    }
}

private struct MessagePopupView: View {
    let model: MessagePopupModel?
    let imageLoader: ImageLoading
    let onTap: (MessagePopupModel) -> Void
    let onDismiss: () -> Void
    @State private var image: UIImage?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        if let model {
            HStack(spacing: 16) {
                if let image {
                    CirclePhoto(image: image, showShadow: false, height: 40)
                } else {
                    Circle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.authorName)
                        .font(.body(16, .bold))

                    Text(model.message)
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
            .offset(y: dragOffset)
            .transition(.move(edge: .top).combined(with: .opacity))
            .contentShape(Rectangle())
            .onTapGesture { onTap(model) }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = min(0, value.translation.height)
                    }
                    .onEnded { value in
                        if value.translation.height < -20 {
                            dragOffset = 0
                            onDismiss()
                        } else {
                            withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                        }
                    }
            )
            .task(id: model.image) {
                image = nil
                guard let url = URL(string: model.image) else { return }
                image = try? await imageLoader.fetchImage(for: url)
            }
        }
    }
}
