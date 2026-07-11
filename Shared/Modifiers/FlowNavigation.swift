//
//  FlowNavigation.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

//Replaces the system back button with the app's own back chevron.
struct FlowNavigation: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
            .toolbar { DismissToolbarItem(type: .back) }
    }
}

extension View {
    func flowNavigation() -> some View {
        modifier(FlowNavigation())
    }
}
