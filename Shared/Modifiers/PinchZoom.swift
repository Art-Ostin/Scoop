//
//  PinchZoom.swift
//  Scoop
//
//  Created by Art Ostin on 15/01/2026.
//

import SwiftUI

//The pinch-to-zoom machinery that lived here was replaced by a package. This wrapper
//remains because ProfileContainer's layout/safe-area context depends on its GeometryReader.
struct ZoomContainer<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { _ in
            content
        }
    }
}
