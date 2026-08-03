//
//  TwoPageScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 27/07/2026.
//

import SwiftUI

struct TwoPageScrollView<Screen1: View, Screen2: View>: View {
    
    @Binding var showSecondScreen: Bool?
    @Binding var scrollProgress: Double

    ///Curve for a page reflowing in place — a row collapsing under it. A page *swap* is left to
    ///the caller's transaction so the height stays in step with the horizontal scroll.
    var reflowAnimation: Animation? = nil

    @ViewBuilder var screen1: () -> Screen1
    @ViewBuilder var screen2: () -> Screen2
    
    @State var screen1Height: CGFloat = 0
    @State var screen2Height: CGFloat = 0
    
    private var activeHeight: CGFloat? {
        let h = (showSecondScreen ?? false) ? screen2Height : screen1Height
        return h > 0 ? h : nil //If 0, make it the natural height (nil) so it measures the height
    }
    
    var body: some View {
        
        HorizontalScrollView(progress: $scrollProgress) {
            screen1()
                .containerRelativeFrame(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { commit($0, to: $screen1Height) }
                .id(false)

            screen2()
                .containerRelativeFrame(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { commit($0, to: $screen2Height) }
                .id(true)
        }
        .scrollPosition(id: $showSecondScreen)
        .clipped()
        .scrollDisabled(true) //Programmatic scroll only
        .frame(height: activeHeight) //Must make the height of each section only as tall as its content
    }

    //A measured height carries the model value, never the presentation one, so the frame above
    //has nothing to interpolate and the page — with the action button riding under it — snaps.
    //Committing the measurement inside the reflow curve gives it one, and does it without an
    //`.animation(value:)` on the frame, which would capture the page swap too. The first
    //measurement is the natural size: it lands unanimated.
    private func commit(_ height: CGFloat, to store: Binding<CGFloat>) {
        guard let reflowAnimation, store.wrappedValue > 0 else {
            store.wrappedValue = height
            return
        }
        withAnimation(reflowAnimation) { store.wrappedValue = height }
    }
}
