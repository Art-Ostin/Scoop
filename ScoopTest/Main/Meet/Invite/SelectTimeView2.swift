//
//  SelectTimeView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

struct SelectTimeView2: View {
    
    @Binding var vm: SendInviteViewModel
    
    @State private var hour: Int = Calendar.current.component(.hour, from: Date())
    @State private var minute: Int = 0
    
    var body: some View {




    }
}

extension SelectTimeView2 {
    
    
    
    private var timePicker: some View {
        HStack {
            Picker("Hour", selection: $hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            
            Picker("Minute", selection: $minute) {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 160, height: 150)
        .labelsHidden()
        .onChange(of: hour) {updateTime()}
        .onChange(of: minute) {updateTime()}
    }
    
    private func updateTime() {
        
    }
}
