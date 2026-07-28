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
    
    @State var screen1Height: CGFloat = 0
    @State var screen2Height: CGFloat = 0
    
    private var activeHeight: CGFloat? {
        let h = (showSecondScreen ?? false) ? screen2Height : screen1Height
        return h > 0 ? h : nil //If 0, make it the natural height (nil) so it measures the height
    }
    
    var body: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            screen1()
                .fixedSize(horizontal: false, vertical: true)
                .getHeight($screen1Height)
                .id(false)
            
            screen2()
                .fixedSize(horizontal: false, vertical: true)
                .getHeight($screen2Height)
                .id(true)
        }
        .scrollPosition(id: $showSecondScreen)
        .clipped()
        .scrollDisabled(true) //Programmatic scroll only
        .frame(height: activeHeight) //Must make the height of each section only as tall as its content
    }
}
