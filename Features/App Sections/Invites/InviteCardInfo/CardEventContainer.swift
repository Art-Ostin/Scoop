
import SwiftUI

struct CardEventContainer: View {
    
    @Bindable var vm: RespondViewModel
    
    @Binding var showQuickInvite: UserProfile?
        
    @Binding var showMessageScreen: Bool
    
    @State var ui = RespondUIState()
    @State private var selectedTab: RespondUIState.Tab = .event
    @State private var pageHeights: [RespondUIState.Tab: CGFloat] = [:]

    var event: UserEvent {vm.respondDraft.originalInvite.event}
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
                .padding(.horizontal, 24) //selectedTab == .event ? 28 :
                .opacity(ui.showTimePopup ? 0.2 : 1)
            
            pageContent
                .frame(height: pageContentHeight)
                .overlayPreferenceValue(InviteCardTimeRowBoundsKey.self) { anchor in
                    GeometryReader { proxy in
                        inviteTimeDropdown(anchor: anchor, in: proxy)
                    }
                }
                .onPreferenceChange(CardEventPageHeightKey.self) { pageHeights in
                    self.pageHeights.merge(pageHeights) { _, new in new }
                }
        }
        .preference(key: IsTimeOpen.self, value: ui.showTimePopup)
        .padding(.top, RespondUIState.CardLayout.topPadding)
        .overlay(alignment: .bottom) {tabIndicatorSection}
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

extension CardEventContainer {
    
    private enum Palette {
        static let primaryText = Color(red: 0.12, green: 0.13, blue: 0.16)
        static let secondaryText = Color(red: 0.36, green: 0.37, blue: 0.4)
    }
    
    private var tabIndicatorSection: some View {
        HStack(spacing: 6) {
            tabIndicator(isSelected: selectedTab == .details)
            tabIndicator(isSelected: selectedTab == .event)
            tabIndicator(isSelected: selectedTab == .message)
        }
        .offset(y: 1)
        .animation(Layout.pageAnimation, value: selectedTab)
        .opacity(ui.showTimePopup ? 0.2 : 1)
    }
    
    private func tabIndicator(isSelected: Bool) -> some View {
        Circle()
            .frame(width: isSelected ? 4 : 3, height: isSelected ? 4 : 3)
            .foregroundStyle(isSelected ? Color.white : Color(red: 0.85, green: 0.85, blue: 0.85)) //Color(red: 0.3, green: 0.3, blue: 0.3)
            .stroke(100, lineWidth: isSelected ? 0.7 : 0, color: Color(red: 0.1, green: 0.1, blue: 0.1))
    }
    
    private enum Layout {
        static let titleAccessoryHeight: CGFloat = 32
        static let pageAnimation = Animation.easeInOut(duration: 0.2)
    }
    
    private var pageContentHeight: CGFloat {
        max(pageHeights.values.max() ?? 0, 1)
    }
    
    
    private var pageContent: some View {
        TabView(selection: $selectedTab) {
            infoPage
                .tag(RespondUIState.Tab.details)
            eventPage
                .tag(RespondUIState.Tab.event)
            messagePage
                .tag(RespondUIState.Tab.message)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: true, isCardInvite: true)
        .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: false, isCardInvite: true)
        .clipped()
    }
    
    private var messagePage: some View {
        InviteCardMessageView(vm: vm, showMessageSection: $ui.showMessageSection, showMessageScreen: $showMessageScreen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .measure(key: CardEventPageHeightKey.self) { proxy in
                [.message: proxy.size.height]
            }
    }
    
    private var eventPage: some View {
        InviteCardEvent(showMessageSection: $ui.showMessageSection, vm: vm, ui: ui)
            .opacity(ui.showMessageSection ? 0 : 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .measure(key: CardEventPageHeightKey.self) { proxy in
                [.event: proxy.size.height]
            }
    }
    
    private var infoPage: some View {
        InviteCardInfo(event: vm.respondDraft.originalInvite.event, user: vm.user, showQuickInvite: $showQuickInvite, decreasePadding: vm.responseType == .modified && vm.respondDraft.newTime.proposedTimes.dates.count == 3)
            .padding(.horizontal, 24)
            .measure(key: CardEventPageHeightKey.self) { proxy in
                [.details: proxy.size.height]
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func inviteTimeDropdown(anchor: Anchor<CGRect>?, in proxy: GeometryProxy) -> some View {
        if let anchor,
           vm.respondDraft.originalInvite.selectedDay != nil {
            let rowRect = proxy[anchor]
            
            InviteCardTimePopup(
                showTimePopup: $ui.showTimePopup,
                vm: vm
            )
            .frame(width: rowRect.width, height: 0, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: rowRect.minX, y: rowRect.maxY)
            .opacity(selectedTab != .event ? 0 : 1)
            .allowsHitTesting(selectedTab == .event && ui.showTimePopup)
            .zIndex(2)
            .offset(y: 16)
            .surfaceShadow(.card)
        }
    }
    
    @ViewBuilder
    private var title: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ZStack(alignment: .leading) {
                switch selectedTab {
                case .message:
                    titleLabel("Invite Messages")
                case .event:
                    titleLabel("\(vm.user.name)'s Invite")
                case .details:
                    titleLabel("\(event.type.description.emoji) \(event.type.longTitle)")
                }
            }
            .transition(.opacity)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack(alignment: .trailing) {
                titleButton
            }
            .frame(height: Layout.titleAccessoryHeight, alignment: .bottomTrailing)
        }
        .animation(Layout.pageAnimation, value: selectedTab)
    }
    
    @ViewBuilder
    private var titleButton: some View {
        ZStack {
            switch selectedTab {
            case .message:
                messageToEventButton
            case .event:
                InviteRespondButton(type: vm.respondDraft.originalInvite.event.type) {
                    selectedTab = .details
                }
                    .scaleEffect(0.9, anchor: .trailing)
                    .fixedSize()
            case .details:
                eventButton
            }
        }
        .transition(.opacity)
    }
    
    
    private var messageToEventButton: some View {
        
        Button {
            withAnimation(Layout.pageAnimation) {
                selectedTab = .event
            }
        } label: {
            HStack(spacing: 4) {
                
                Image(systemName: "chevron.left")
                    .font(.body(11, .bold))

                
                Text("event")
                    .font(.body(12, .bold))
                    .foregroundStyle(Palette.secondaryText)
            }
            .foregroundStyle(Palette.secondaryText)
            .padding(5)
            .padding(.horizontal, 6.5)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
            )
            .offset(y: -2)
        }
    }
    
    private func titleLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("SFProRounded-Semibold", size: 20))
            .foregroundStyle(Palette.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
    }
    
    private var eventButton: some View {
        Button {
            withAnimation(Layout.pageAnimation) {
                selectedTab = .event
            }
        } label: {
            HStack(spacing: 4) {
                Text("event")
                    .font(.body(12, .bold))
                    .foregroundStyle(Palette.secondaryText)

                
                Image(systemName: "chevron.right")
                    .font(.body(11, .bold))
            }
            .foregroundStyle(Palette.secondaryText)
            .padding(5)
            .padding(.horizontal, 6.5)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
            )
            .offset(y: -2)
        }
    }
}

private struct CardEventPageHeightKey: PreferenceKey {
    static var defaultValue: [RespondUIState.Tab: CGFloat] = [:]

    static func reduce(value: inout [RespondUIState.Tab: CGFloat], nextValue: () -> [RespondUIState.Tab: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct IsTimeOpen: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}


/*
 private var messageToEventButton: some View {
     Button {
         withAnimation(.easeInOut(duration: 0.2)) {
             selectedTab = .event
         }
     } label: {
         HStack(spacing: 4) {
             Image(systemName: "chevron.left")
                 .font(.body(11, .bold))

             
             Text("event")
         }
         .font(.body(12, .bold))
         .foregroundStyle(Palette.secondaryText)
         .padding(5)
         .padding(.horizontal, 6.5)
         .background(.white)
         .cornerRadius(100)
         .overlay(
             RoundedRectangle(cornerRadius: 100)
                 .inset(by: 0.1)
                 .stroke(Color.appGreen, lineWidth: 0.2)
         )
         .contentShape(.rect)
     }
     .offset(y: -2)
 }
 */
