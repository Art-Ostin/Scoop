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

//One definition for the flight copy and the settled carousel, so the settle handoff renders identically.
struct InviteBackButton: View {
    let action: () -> Void

    var body: some View {
        ScoopButton(shape: Capsule(), action: action) {
            HStack(spacing: 6) {
                
                Text("Hide")
                    .font(.body(14, .bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
        .padding(.top, 56)
    }
}

struct BottomBackButton: View {
    
    let action: () -> Void
    
    var body: some View {
        ScoopButton(shape: Capsule(), action: action) {
            HStack(spacing: 6) {
                Text("Hide")
                    .font(.body(14, .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .padding(.top, 48)
        .padding(.horizontal, 6)
    }
}


struct PagedScrollStyle: ViewModifier {
    @Binding var scrolledPageID: Int?
    @Binding var pageWidth: CGFloat
    @Binding var scrollProgress: Double
    let pageCount: Int
    var dragDisabled: Bool = false //True while the invite card's swipe-dismiss owns the touch; kills in-flight pans too

    func body(content: Content) -> some View {
        content
            .scrollPosition(id: $scrolledPageID)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
            .trackScrollProgress(scrollProgress: $scrollProgress)
            .scrollIndicators(.hidden)
            .scrollDisabled(pageCount <= 1 || dragDisabled)
            //.paging strides by viewport width: visual gaps must live inside the page
            //cells (widened viewport), never as HStack spacing — pages drift by the gap.
            .scrollTargetBehavior(.paging)
    }
}

