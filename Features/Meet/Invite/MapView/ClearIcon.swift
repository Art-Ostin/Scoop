//
//  ClearIcon.swift
//  Scoop
//
//  Created by Art Ostin on 09/02/2026.
//

import SwiftUI

struct ClearIcon: View {
    
    @Bindable var vm: MapViewModel
    
    var type: MapIconStyle? {
        vm.selectedMapCategory
    }
    
    var gradient: LinearGradient {
        type?.gradient ?? LinearGradient(colors: [.accent, Color.appColorTint], startPoint: .bottom, endPoint: .top)
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
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

                VStack(spacing: 0) {
                    if let type {
                        labelClear(type: type)
                    } else {
                        VStack(spacing: 2) {
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
    
    private func labelClear(type: MapIconStyle) -> some View {
        VStack(spacing: 0) {
            type.image
                .renderingMode(.template)
                .foregroundStyle(.black.opacity(0.8))
                .scaleEffect(0.6)
            
            Text("Clear")
                .foregroundStyle(Color.gray)
                .font(.body(10, .medium))
                .offset(y: -2)
        }
    }
}

