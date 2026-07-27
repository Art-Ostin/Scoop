//
//  TwoPageScrollView.swift
//  Scoop Test
//
//  Created by Art Ostin on 27/07/2026.
//

import SwiftUI

struct TwoPageScrollView<Screen1: View, Screen2: View>: View {
    
    @Binding var showSecondScreen: Bool?
    @Binding var scrollProgress: Double
    
    @ViewBuilder var screen1: () -> Screen1
    @ViewBuilder var screen2: () -> Screen2
    
    
    var body: some View {
        HorizontalPageScroll(progress: $scrollProgress) {
            screen1()
                .id(false)
            
            screen2()
                .id(true)
        }
        .scrollPosition(id: $showSecondScreen)
        .animation(.snappy, value: showSecondScreen)
    }
}
