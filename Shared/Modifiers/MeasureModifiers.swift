//
//  FetchPositions.swift
//  Scoop Test
//
//  Created by Art Ostin on 15/06/2026.
//

import SwiftUI
//All Logic with 'Get Bottom'

extension View {
    //Gets the imageSize based of screen width
    func getImageSize(imageSize: Binding<CGFloat>, horizontalPadding: CGFloat) -> some View {
        self
            .onGeometryChange(for: CGFloat.self) {$0.size.width} action: { screenWidth in
                imageSize.wrappedValue = screenWidth - (horizontalPadding * 2)
            }
    }
    
    //reports the Y position of the view's bottom edge (maxY),
    func getBottom(coordinateSpace: String, bottom: Binding<CGFloat>) -> some View {
        self
            .onGeometryChange(for: CGFloat.self) { geo in
                geo.frame(in: .named(coordinateSpace)).maxY
            } action: { bottomPosition in
                if bottom.wrappedValue < 25 { //Updates only once. If less than 25 it indicates still on transient
                    bottom.wrappedValue = bottomPosition
                }
            }
    }
}
