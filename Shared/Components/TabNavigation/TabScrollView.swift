//
//  TabScrollView.swift
//  Scoop Test
//
//  Created by Art Ostin on 11/07/2026.

import SwiftUI

//1. All Tab Views have (1) A Navigation Stack (2) A Scroll View (3) Generic modifiers (like title)
//4. An If else statement to show placeholder or not. This structure standardises the pattern

struct TabScrollView<Content: View>: View {
    //Inputs
    let type: AppTab
    let showEmptyView: Bool
    
    @Binding var path: NavigationPath
    
    @ViewBuilder let content: Content
    
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                if showEmptyView {
                    
                } else {
                    content
                }
            }
            .background(type == .meet && !showEmptyView ? Color.appCanvas.ignoresSafeArea() : Color.clear.ignoresSafeArea())
            .scrollIndicators(.never)
            .navigationTitle(title)
            .scoopNavigationBarFonts() //Meet title wired up
        }
    }
}


