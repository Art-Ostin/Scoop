//
//  InviteComponents.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI


struct RowCaption: View {
    enum Label: String { case what, when, `where` }

    let label: Label
    let dimmed: Bool

    var body: some View {
        Text(label.rawValue.capitalized)
            .font(.body(12, .regular))
            .foregroundStyle(Color.textTertiary)
            .opacity(dimmed ? 0.3 : 1)
    }
}

enum InviteRowMetrics {
    //Every row is its visible content plus the same 22pt inset above and below.
    //That makes adjacent content blocks exactly 44pt apart while preserving the
    //original 64pt cadence for a single 20pt line.
    static let verticalPadding: CGFloat = 22
    static let primaryLineHeight: CGFloat = 20
    static let secondaryLineHeight: CGFloat = 16

    static let indicatorGap: CGFloat = 5
    static let indicatorHeight: CGFloat = 3
    static let locationLineSpacing: CGFloat = 4

    static let singleLineContentHeight = primaryLineHeight
    static let indicatorContentHeight = primaryLineHeight + indicatorGap + indicatorHeight
    static let locationContentHeight = primaryLineHeight + locationLineSpacing + secondaryLineHeight

    static func rowHeight(contentHeight: CGFloat) -> CGFloat {
        contentHeight + 2 * verticalPadding
    }

    static func contentHeight(showsIndicator: Bool) -> CGFloat {
        showsIndicator ? indicatorContentHeight : singleLineContentHeight
    }

    static func rowHeight(showsIndicator: Bool) -> CGFloat {
        rowHeight(contentHeight: contentHeight(showsIndicator: showsIndicator))
    }

    static let messageLineSpacing = max(
        0,
        secondaryLineHeight - UIFont.body(12, .regular).lineHeight
    )
}

//The compact row pager indicator at its real rendered size. Keeping the size in
//layout (instead of scaling a larger overlay) makes it part of the row's content.
struct InvitePageIndicator: View {
    let count: Int
    let progress: Double

    var body: some View {
        PageIndicator(
            count: count,
            progress: progress,
            dotSize: 3,
            inactiveDotSize: 3,
            activeWidth: 5,
            spacing: 5,
            activeColor: .textSecondary
        )
        .frame(height: InviteRowMetrics.indicatorHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension EnvironmentValues {
    @Entry var isLiveInviteRow: Bool = false
}

//The invite carousel's options-menu label.
struct InviteOptionsIcon: View {
    var body: some View {
        Image(systemName: "ellipsis")
            .font(.body(16, .bold))
            .foregroundStyle(Color.textSecondary)
            .frame(width: 30, height: 30)
            .glassEffectIfAvailable(shape: Circle())
            .scaleEffect(0.9, anchor: .bottom)
    }
}

struct BottomBackButton: View {
    
    let action: () -> Void
    
    var body: some View {
        ScoopButton(shape: Circle(), action: action) {
            Image(systemName: "chevron.down")
                .font(.body(17))
                .fontWeight(.heavy)
                .frame(width: 45, height: 45)
        }
        .padding(.top, Spacing.xl)
    }
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
            .pagedScroll(progress: $scrollProgress)
    }
}
