//
//  ClearIcon.swift
//  Scoop
//
//  Created by Art Ostin on 09/02/2026.
//

import SwiftUI

struct ClearIcon: View {
    
    @Bindable var vm: MapViewModel
    
    var type: MapCategory? {
        vm.selectedMapCategory
    }
    
    var gradient: LinearGradient {
        type?.gradient ?? LinearGradient(colors: [.accent, .accent], startPoint: .bottom, endPoint: .top)
    }
    
    var body: some View {
        Button {
            if type != nil {
                vm.selectedMapCategory = nil
            } else {
                print("Random Place Here")
            }
        } label: {
            ZStack {
                Circle()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.white)
                    .overlay(
                        Circle().stroke(gradient, lineWidth: 1)
                    )
                    .shadow(.floating)

                VStack(spacing: 0) {
                    if let type {
                        labelClear(category: type)
                    } else {
                        VStack(spacing: Spacing.hairline) {
                            Image("RandomPlace")
                                .scaleEffect(0.90)
                            Text("Random")
                                .font(.body(8, .medium))
                                .foregroundStyle(Color.black.opacity(0.85))
                        }
                        .offset(y: -1)
                    }
                }
            }
        }
        .scaleEffect(0.95)
    }
}

extension ClearIcon {
    
    private func labelClear(category: MapCategory) -> some View {
        VStack(spacing: 0) {
            category.image
                .renderingMode(.template)
                .tint(Color.textTertiary)
                .scaleEffect(0.6)
            
            Text("Clear")
                .tint(Color.textTertiary)
                .font(.body(10, .medium))
                .offset(y: -2)
        }
    }
}

