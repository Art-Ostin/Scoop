//
//  HideToolbarBackground.swift
//  Scoop
//
//  Created by Art Ostin on 03/06/2026.
//

import SwiftUI


extension ToolbarContent {
    @ToolbarContentBuilder
    func hideToolbarBackground() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            self
                .sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
