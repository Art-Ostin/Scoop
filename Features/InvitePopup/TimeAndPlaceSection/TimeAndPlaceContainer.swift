//
//  InviteRowContainer.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI

struct TimeAndPlacePage: View {

    @Bindable var ui: TimeAndPlaceUIState
    @Binding var draft: EventFieldsDraft
    @Binding var showMessageScreen: Bool
    
    let tint: Color
    
    var body: some View {
        VStack(spacing: 0) {
            InviteTypeRow(ui: ui, type: $draft.type, unparsedMessage: $draft.message, showMessageScreen: $showMessageScreen)
            InviteTimeRow(ui: ui, proposedTimes: $draft.time)
            InvitePlaceRow(ui: ui, eventLocation: $draft.place)
        }
        .padding(.top, Spacing.xxs)
        .padding(.bottom, draft.place == nil ? 6 : 0)
        .padding(.horizontal, Spacing.lg)
        .zIndex(1)
        .background(alignment: .top) {
            LinearGradient(colors: [tint.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 50)
        }
    }
}


struct RowCaption: View {
    enum Label: String { case what, when, `where` }

    let label: Label

    var body: some View {
        Text(label.rawValue.capitalized)
            .font(.body(13, .medium))
            .foregroundStyle(Color.textTertiary)
    }
}




enum InviteRowMetrics {
    //Rows use a 22pt inset by default. Indicator rows tighten their bottom inset
    //by 4pt, while a populated Place row tightens its top inset by 2pt.
    static let verticalPadding: CGFloat = 22
    static let indicatorBottomPadding: CGFloat = 18
    static let populatedPlaceTopPadding: CGFloat = 20
    static let indicatorCaptionOffset: CGFloat = 2
    static let valueChevronSpacing: CGFloat = 9
    static let primaryLineHeight: CGFloat = 20
    static let secondaryLineHeight: CGFloat = 16
    
    static let confirmInviteSpacing: CGFloat = 26

    static let indicatorGap: CGFloat = 5
    static let indicatorHeight: CGFloat = 3
    static let locationLineSpacing: CGFloat = 0

    static let singleLineContentHeight = primaryLineHeight
    static let indicatorContentHeight = primaryLineHeight + indicatorGap + indicatorHeight
    static let locationContentHeight = primaryLineHeight + locationLineSpacing + secondaryLineHeight

    static func contentHeight(showsIndicator: Bool) -> CGFloat {
        showsIndicator ? indicatorContentHeight : singleLineContentHeight
    }

    static func bottomPadding(showsIndicator: Bool) -> CGFloat {
        showsIndicator ? indicatorBottomPadding : verticalPadding
    }

    static func rowHeight(showsIndicator: Bool) -> CGFloat {
        contentHeight(showsIndicator: showsIndicator)
            + verticalPadding
            + bottomPadding(showsIndicator: showsIndicator)
    }

    static func primaryContentOffset(showsIndicator: Bool) -> CGFloat {
        verticalPadding + singleLineContentHeight / 2
            - rowHeight(showsIndicator: showsIndicator) / 2
    }

    static let messageLineSpacing = max(
        0,
        secondaryLineHeight - UIFont.body(12, .regular).lineHeight
    )
}

extension EnvironmentValues {
    @Entry var isLiveInviteRow: Bool = false
}

struct PagedScrollStyle: ViewModifier {
    @Binding var scrolledPageID: Int?
    @Binding var pageWidth: CGFloat
    @Binding var scrollProgress: Double
    let pageCount: Int

    func body(content: Content) -> some View {
        content
            .scrollPosition(id: $scrolledPageID)
            .getWidth($pageWidth)
            .scrollDisabled(pageCount <= 1)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .trackScrollProgress(scrollProgress: $scrollProgress)
    }
}
