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
    static let rowHeight: CGFloat = 72
}

extension EnvironmentValues {
    @Entry var isLiveInviteRow: Bool = false
}

extension View {
    func readGlobalFrame(into frame: Binding<CGRect>) -> some View {
        onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame.wrappedValue = $0 }
    }
}

//One definition for the flight replica and the settled carousel's menu label, so the settle handoff renders identically.
struct InviteOptionsIcon: View {
    var body: some View {
        Image(systemName: "ellipsis")
            .font(.body(16, .bold))
            .foregroundStyle(Color.textSecondary)
            .frame(width: 30, height: 30)
            .glassBackgroundIfAvailable(shape: Circle(), isClear: false)
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
        .padding(.top, 36)
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
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
            .trackScrollProgress(scrollProgress: $scrollProgress)
            .scrollIndicators(.hidden)
            .scrollDisabled(pageCount <= 1)
            .scrollTargetBehavior(.paging)
    }
}

