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
    //Rows use a 22pt inset by default. Indicator rows tighten their bottom inset
    //by 4pt, while a populated Place row tightens its top inset by 2pt.
    static let verticalPadding: CGFloat = 22
    static let indicatorBottomPadding: CGFloat = 18
    static let populatedPlaceTopPadding: CGFloat = 20
    static let indicatorCaptionOffset: CGFloat = 2
    static let valueChevronSpacing: CGFloat = 9
    static let primaryLineHeight: CGFloat = 20
    static let secondaryLineHeight: CGFloat = 16

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

//The compact row pager indicator at its real rendered size. Keeping the size in
//layout (instead of scaling a larger overlay) makes it part of the row's content.
struct InvitePageIndicator: View {
    let count: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                let closeness = max(0, 1 - abs(progress - Double(index)))

                Capsule()
                    .fill(Color.border)
                    .overlay {
                        Capsule()
                            .fill(Color.textSecondary)
                            .opacity(closeness)
                    }
                    .frame(width: 3 + 2 * CGFloat(closeness), height: 3)
            }
        }
        .frame(width: count > 0 ? 5 + CGFloat(count - 1) * 8 : 0, height: 3)
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
