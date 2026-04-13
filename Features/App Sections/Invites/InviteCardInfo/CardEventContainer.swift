//
//  CardInfoContainer.swift
//  Scoop
//
//  Created by Art Ostin on 12/04/2026.
//


import SwiftUI

struct CardEventContainer: View {
    
    @Bindable var vm: RespondViewModel
    @State var ui = RespondUIState()
    @State private var pageHeights: [Bool: CGFloat] = [:]
    let name: String
    var event: UserEvent {vm.respondDraft.originalInvite.event}
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
                .padding(.horizontal, 24)
            
            TabView(selection: $ui.showMeetInfo) {
                InviteCardEvent(vm: vm, ui: ui, name: name)
                    .padding(.horizontal, 24)
                    .measure(key: CardEventPageHeightKey.self) { proxy in
                        [false: proxy.size.height]
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .leading))
                    .tag(false)

                InviteCardInfo(event: event)
                    .padding(.horizontal, 24)
                    .measure(key: CardEventPageHeightKey.self) { proxy in
                        [true: proxy.size.height]
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .trailing))
                    .tag(true)
            }
            .animation(.easeInOut(duration: 0.2), value: ui.showMeetInfo)
            .frame(height: selectedPageHeight)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: true)
            .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: false)
            .modifier(ConditionClipped(isClipped: !ui.showTimePopup))
            .onPreferenceChange(CardEventPageHeightKey.self) { pageHeights in
                self.pageHeights = pageHeights
            }
        }
        .padding(.top, RespondUIState.CardLayout.topPadding)
        .padding(.bottom, RespondUIState.CardLayout.bottomPadding)
    }
}

extension CardEventContainer {
    
    private enum Layout {
        static let titleAccessoryHeight: CGFloat = 32
    }

    private var selectedPageHeight: CGFloat {
        let fallbackHeight = max(pageHeights.values.max() ?? 0, 1)
        return max(pageHeights[ui.showMeetInfo] ?? fallbackHeight, 1)
    }
    
    @ViewBuilder
    private var title: some View {
        let titleText = ui.showMeetInfo ? "\(event.type.description.emoji) \(event.type.longTitle)" : "\(name)'s Invite"
    
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
            InviteRespondButton(type: vm.respondDraft.originalInvite.event.type, showInfo: $ui.showMeetInfo)
                .scaleEffect(0.9, anchor: .trailing)
                .fixedSize()
        }
    }
    
    private var eventButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                ui.showMeetInfo = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.body(14, .bold))
                    .foregroundStyle(Color.appGreen)

                Text("Event")
                    .foregroundStyle(Color.appGreen)
                    .font(.custom("SFProRounded-Bold", size: 12))
            }
            .padding(4)
            .kerning(0.5)
            .padding(.horizontal, 6)
            .stroke(16, lineWidth: 1, color: Color.appGreen.opacity(0.2))
        }
        .buttonStyle(.plain)
    }
}

struct ConditionClipped: ViewModifier {
    let isClipped: Bool
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if isClipped {
            content.clipped()
        } else {
            content
        }
    }
}

private struct CardEventPageHeightKey: PreferenceKey {
    static var defaultValue: [Bool: CGFloat] = [:]

    static func reduce(value: inout [Bool: CGFloat], nextValue: () -> [Bool: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: max)
    }
}


/*
 import SwiftUI

 struct CardEventContainer: View {
     
     @Bindable var vm: RespondViewModel
     @State var ui = RespondUIState()
     let name: String
     var event: UserEvent {vm.respondDraft.originalInvite.event}
     
     @State var tabSelection: Int = 0
     var body: some View {
         VStack(alignment: .leading, spacing: 0) {
             title
                 .padding(.horizontal, 24)
             
             TabView(selection: $tabSelection) {
                 InviteCardEvent(vm: vm, ui: ui, name: name)
                     .padding(.horizontal, 24)
                     .transition(.move(edge: .leading))
                     .tag(0)

                 
                 InviteCardInfo(event: event)
                     .padding(.horizontal, 24)
                     .transition(.move(edge: .trailing))
                     .tag(1)
             }
             .tabViewStyle(.page)
             .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
             .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: true)
             .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: false)
             .modifier(ConditionClipped(isClipped: !ui.showTimePopup))
         }
         .animation(.easeInOut(duration: 0.2), value: tabSelection)
         .padding(.top, RespondUIState.CardLayout.topPadding)
         .padding(.bottom, RespondUIState.CardLayout.bottomPadding)
         .animation(.easeInOut(duration: 0.2), value: ui.showMeetInfo)
         .onChange(of: ui.showMeetInfo) { oldValue, newValue in
             if newValue {
                 tabSelection = 1
             }
         }
     }
 }

 extension CardEventContainer {
     
     private enum Layout {
         static let titleAccessoryHeight: CGFloat = 32
     }
     
     @ViewBuilder
     private var title: some View {
         let titleText = tabSelection == 0 ? "\(event.type.description.emoji) \(event.type.longTitle)" : "\(name)'s Invite"
     
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
         if tabSelection == 1 {
             eventButton
         } else {
             InviteRespondButton(type: vm.respondDraft.originalInvite.event.type, showInfo: $ui.showMeetInfo)
                 .scaleEffect(0.9, anchor: .trailing)
                 .fixedSize()
         }
     }
     
     private var eventButton: some View {
         Button {
             ui.showMeetInfo = false
         } label: {
             HStack(spacing: 6) {
                 Image(systemName: "chevron.left")
                     .font(.body(14, .bold))
                     .foregroundStyle(Color.appGreen)

                 Text("Event")
                     .foregroundStyle(Color.appGreen)
                     .font(.custom("SFProRounded-Bold", size: 12))
             }
             .padding(4)
             .kerning(0.5)
             .padding(.horizontal, 6)
             .stroke(16, lineWidth: 1, color: Color.appGreen.opacity(0.2))
         }
         .buttonStyle(.plain)
     }
 }

 struct ConditionClipped: ViewModifier {
     let isClipped: Bool
     
     @ViewBuilder
     func body(content: Content) -> some View {
         if isClipped {
             content.clipped()
         } else {
             content
         }
     }
 }

 */
