//
//  InviteTypeRow.swift
//  Scoop Test
//
//  Created by Art Ostin on 04/09/2026.
//

import SwiftUI


private let chevronSpacing: CGFloat = 9
private let rowHeight: CGFloat = 33

struct InviteTypeRow: View {
    
    //Injected Data to updated
    @Binding var eventType: Event.EventType
    @Binding var message: String?
    
    //Reading 4 states from UI, so passing in whole binding
    @Bindable var ui: ComposeInviteUIState
    let rowHeightIncrease: CGFloat = 19.5 //As need to fit 3 line text on it so fixes bug.
    let timePopupOpen: Bool
    
    //Store which 'info' icons for the selectTypeDowndown open
    @State private var openInfoTypes: Set<Event.EventType> = []
    
    //ScrollProgress Logic
    @State private var messageWidth: CGFloat = 0
    @State private var scrollProgress: Double = 0
    @State private var scrollPosition = ScrollPosition()
    
    var body: some View {
        HStack {
            caption
            Spacer(minLength: 20)//Fine tuned looks good with this
            dropDownMenu
        }
        .frame(minHeight: rowHeight)
        .blurPop(visible: !timePopupOpen, scale: 1)
    }
    
    private var dropDownMenu: some View {
        DropdownCustomMenu(
            isOpen: $ui.typePopupOpen,
            showMessageScreen: $ui.showMessageScreen,
            message: message ?? "",
            onClose: { openInfoTypes.removeAll() },
            pressEffect: isOnMessagePage ? .subtleShrink : .shrink,
            content: { selectTypeView },
            label:   { typeLabel }
        )
    }
    
    //The type view I open up
    private var selectTypeView: some View {
        SelectTypeView(
            openTypes: $openInfoTypes,
            selectedType: $eventType,
            showMessageScreen: $ui.showMessageScreen,
            message: message ?? ""
        )
    }
    
    private var infoIcon: some View {
        Button {
            ui.showInfoScreen = true
        } label: {
            SmallInfoIcon()
                .scaleEffect(0.8)
                .expandHitArea()
                .offset(x: 16, y: -2)
        }
    }
    
    private var typeLabel: some View {
        HStack(spacing: chevronSpacing) {
            typePager
                .padding(.top,    -(rowHeightIncrease/2 + contentLift))
                .padding(.bottom, -(rowHeightIncrease/2 - contentLift))
            DropDownButton(isOpen: ui.typePopupOpen)
        }
    }
    
    private var typePager: some View {
        HorizontalScrollView(
            progress: $scrollProgress,
            alignment: .center,
            position: $scrollPosition) {
                typeTitle.id(0)
                
                if let visibleMessage { eventMessage(text: visibleMessage).id(1) }
            }
            .mask { edgeFadeMask }                          // ← new: fades the pages only
            .animation(.easeOut(duration: 0.06), value: isScrolling)
            .overlay(alignment: .bottomTrailing) {if visibleMessage != nil {pageIndicator } }
            .scrollDisabled(visibleMessage == nil)
            .onChange(of: message) { scrollPosition.scrollTo(id: 1) }
    }
    
    private var isOnMessagePage: Bool { scrollProgress > 0.5 }
    
    private var caption: some View {
        captionContent
            .overlay(alignment: .topTrailing) { infoIcon }
            .frame(width: 48, alignment: .leading)
            .animation(.transition, value: isOnMessagePage)
    }
    
    private var captionContent: some View {
        ZStack {
            if isOnMessagePage {
                Text(eventType.longTitle)
                    .font(.body(13, .medium))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.blurReplace)
            } else {
                RowCaption(label: .what)
                    .transition(.blurReplace)
            }
        }
    }
    
    private var pageIndicator: some View {
        InvitePageIndicator(count: 2, progress: scrollProgress)
            .animation(.move, value: indicatorOffset)
            .offset(y: indicatorOffset)
    }
    
    private var typeTitle: some View {
        EventRowText(text: eventType.longTitle)
            .containerRelativeFrame(.horizontal, alignment: .trailing)
            .frame(height: rowHeight + rowHeightIncrease)
            .offset(y: contentLift) //Cancels the box lift: only the message page should rise
    }
    
    
    //Key fixes bug
    private var visibleMessage: String? {
        guard let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return message
    }
    
    private func eventMessage(text: String) -> some View {
        Text(text)
            .font(.body(14, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background { Color.clear.getWidth($messageWidth) }
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.trailing)
            .containerRelativeFrame(.horizontal)
            .frame(height: rowHeight + rowHeightIncrease)
            .offset(y: messageLineCount == 2 ? -5 : 0) //3 lines lift via contentLift instead: no slack to translate into
    }
    
    private var messageLineCount: Int {
        let metrics = visibleMessage?.lineMetrics(
            font: .body(14, .regularItalic), //lineMetrics' contract: must match the drawn Text exactly
            lineSpacing: 0,                  //The drawn Text sets none
            width: messageWidth
        )
        return metrics?.count ?? 0
    }
    
    //Three lines fill the page to within 1.05pt, so the lift has to move the BOX, not the content
    private var contentLift: CGFloat { messageLineCount == 3 ? 5 : 0 }

    private var indicatorOffset: CGFloat {
        guard scrollProgress > 0.5 else { return -6 }   //Title page: no nudge
        return switch messageLineCount {
            case 1:  -6
            case 2:  -4
            default:  5 //+2 on the lift, so the gap to a 3-line message widens rather than rides up
        }
    }
    
    
    private var isScrolling: Bool { scrollProgress > 0.01 && scrollProgress < 0.99 }

    private var edgeFadeMask: some View {
        let w: CGFloat = isScrolling ? Spacing.md : 0
        return HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing).frame(width: w)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: w)
        }
    }
}
