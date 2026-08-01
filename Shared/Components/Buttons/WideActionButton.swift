//
//  WideActionButton.swift
//  Scoop
//
//  Created by Art Ostin on 20/07/2026.
//

import SwiftUI

struct WideActionButton: View {

    //Injected
    let text: String
    let isActive: Bool
    var showShadow: Bool = true
    var font: Font = .body(18, .bold)
    var lineLimit: Int = 1

    let onTap: () -> ()

    var body: some View {
        ScoopButton(
            style: .tinted(isActive ? .textAccent : .fillGray,
                           shadow: (showShadow && isActive) ? .button : nil,
                           glass: isActive),
            shape: .capsule,
            action: onTap
        ) {
            label
        }
        .disabled(!isActive)
    }

    private var label: some View {
        //Need Zstack, to get blur replace of text when it changes
        ZStack {
               Text(text)
                   .font(font)
                   .lineLimit(lineLimit)
                   .multilineTextAlignment(.center)
                   .id(text)
                   .transition(.blurReplace)
           }
           .animation(.transition, value: text)
           .frame(maxWidth: .infinity)
           .frame(height: 48)
           .geometryGroup()
    }
}
