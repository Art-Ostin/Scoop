//
//  TimePicker.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct TimePicker: View {
    
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int

    static let height: CGFloat = 120 //Geometry: selection ± 60; the neighbouring rows end 42pt out
    private static let dissolveFrom: CGFloat = 40 //Geometry: selected-row centre → the neighbouring row's far edge (one ~30pt pitch + half a numeral)
    private static let dissolveTo: CGFloat = 48   //Geometry: the rim, where the next row folds away
    private static let inkEnd: CGFloat = (height / 2 - dissolveFrom) / height
    private static let clearEnd: CGFloat = (height / 2 - dissolveTo) / height
    
    var body: some View {
        HStack {
            Picker("Hour", selection: $selectedHour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                        .foregroundStyle(Color.textPrimary)
                }
            }

            Picker("Minute", selection: $selectedMinute) {
                ForEach([00, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 160, height: Self.height)
        .labelsHidden()
        .tint(.accent)
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: Self.clearEnd),
                                   .init(color: .black, location: Self.inkEnd),
                                   .init(color: .black, location: 1 - Self.inkEnd),
                                   .init(color: .clear, location: 1 - Self.clearEnd)],
                           startPoint: .top, endPoint: .bottom)
        }
        .frame(maxWidth: .infinity)
    }
}

//Mount before presenting a wheel picker so UIKit completes its one-time setup offscreen.
struct TimePickerWarmUp: View {
    var body: some View {
        HStack(spacing: 0) {
            Picker("", selection: .constant(0)) { Text("0").tag(0) }
            Picker("", selection: .constant(0)) { Text("0").tag(0) }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: 1, height: 1)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
