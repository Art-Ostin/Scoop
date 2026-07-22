//
//  TimePicker.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct TimePicker: View {
    
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    
    var body: some View {
        HStack {
            Picker("Hour", selection: $selectedHour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                        .foregroundStyle(Color.black)
                }
            }

            Picker("Minute", selection: $selectedMinute) {
                ForEach([00, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                        .foregroundStyle(Color.black)
                }
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 160, height: 130)
        .labelsHidden()
        .tint(.accent)
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
