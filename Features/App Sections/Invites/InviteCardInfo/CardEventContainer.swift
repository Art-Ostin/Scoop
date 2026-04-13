//
//  CardInfoContainer.swift
//  Scoop
//
//  Created by Art Ostin on 12/04/2026.
//
import SwiftUI

struct CardEventContainer: View {
    
    @Bindable var vm: RespondViewModel
    @Binding var showQuickInvite: UserProfile?
    
    @State var ui = RespondUIState()
    @State private var pageHeights: [Bool: CGFloat] = [:]
    
    
    var event: UserEvent {vm.respondDraft.originalInvite.event}
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
                .padding(.horizontal, 24)
            
            pageContent
                .animation(Layout.pageAnimation, value: selectedPageHeight)
                .frame(height: selectedPageHeight)
                .overlayPreferenceValue(InviteCardTimeRowBoundsKey.self) { anchor in
                    GeometryReader { proxy in
                        inviteTimeDropdown(anchor: anchor, in: proxy)
                    }
                }
                .onPreferenceChange(CardEventPageHeightKey.self) { pageHeights in
                    self.pageHeights = pageHeights
                }
        }
        .padding(.top, RespondUIState.CardLayout.topPadding)
        .padding(.bottom, RespondUIState.CardLayout.bottomPadding)
//        .overlay(alignment: .bottomTrailing) {
//            if ui.showMeetInfo {
//                cantMakeItButton
//            }
//        }
    }
}

extension CardEventContainer {
    
    private enum Layout {
        static let titleAccessoryHeight: CGFloat = 32
        static let pageAnimation = Animation.easeInOut(duration: 0.2)
    }

    private var selectedPageHeight: CGFloat {
        let fallbackHeight = max(pageHeights.values.max() ?? 0, 1)
        return max(pageHeights[ui.showMeetInfo] ?? fallbackHeight, 1)
    }

    private var animatedShowMeetInfo: Binding<Bool> {
        $ui.showMeetInfo.animation(Layout.pageAnimation)
    }

    private var pageContent: some View {
        TabView(selection: animatedShowMeetInfo) {
            eventPage
                .tag(false)

            infoPage
                .tag(true)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: true)
        .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: false)
        .clipped()
    }

    private var eventPage: some View {
        InviteCardEvent(vm: vm, ui: ui, name: vm.user.name)
            .padding(.horizontal, 24)
            .measure(key: CardEventPageHeightKey.self) { proxy in
                [false: proxy.size.height]
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var infoPage: some View {
        InviteCardInfo(event: vm.respondDraft.originalInvite.event, user: vm.user, showQuickInvite: $showQuickInvite)
            .padding(.horizontal, 24)
            .measure(key: CardEventPageHeightKey.self) { proxy in
                [true: proxy.size.height]
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func inviteTimeDropdown(anchor: Anchor<CGRect>?, in proxy: GeometryProxy) -> some View {
        if ui.showMeetInfo == false,
           let anchor,
           vm.respondDraft.originalInvite.selectedDay != nil {
            let rowRect = proxy[anchor]

            InviteCardTimePopup(
                showTimePopup: $ui.showTimePopup,
                vm: vm
            )
            .frame(width: rowRect.width, height: 0, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: rowRect.minX, y: rowRect.maxY)
            .zIndex(2)
        }
    }
    
    @ViewBuilder
    private var title: some View {
        let titleText = ui.showMeetInfo ? "\(event.type.description.emoji) \(event.type.longTitle)" : "\(vm.user.name)'s Invite"
    
        HStack(alignment: .bottom, spacing: 12) {
            Text(titleText)
                .contentTransition(.interpolate)
                .font(.custom("SFProRounded-Bold", size: 20))
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            titleAccessory
                .frame(height: Layout.titleAccessoryHeight, alignment: .bottomTrailing)
        }
    }
    
    @ViewBuilder
    private var titleAccessory: some View {
        if ui.showMeetInfo {
            eventButton
        } else {
            InviteRespondButton(type: vm.respondDraft.originalInvite.event.type, showInfo: animatedShowMeetInfo)
                .scaleEffect(0.9, anchor: .trailing)
                .fixedSize()
        }
    }

    private var cantMakeItButton: some View {
        Button {
            showQuickInvite = vm.user
        } label: {
            Text("Can't make it?")
                .font(.body(12, .bold))
                .foregroundStyle((Color(red: 0.35, green: 0.35, blue: 0.35)))
                .kerning(0.5)
                .offset(y: 3)
        }
    }
    
    private var eventButton: some View {
        Button {
            withAnimation(.easeInOut) {
                animatedShowMeetInfo.wrappedValue = false
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.appGreen)

                Text("Event")
                    .foregroundStyle(Color.appGreen)
                    .font(.custom("SFProRounded-Bold", size: 12))
            }
            .padding(2)
            .kerning(0.5)
            .padding(.horizontal, 8)
            .stroke(16, lineWidth: 1, color: Color(red: 0, green: 0.53, blue: 0.45))
            .offset(y: -3)
        }
        .buttonStyle(.plain)
    }
}

private struct CardEventPageHeightKey: PreferenceKey {
    static var defaultValue: [Bool: CGFloat] = [:]

    static func reduce(value: inout [Bool: CGFloat], nextValue: () -> [Bool: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: max)
    }
}
