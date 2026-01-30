//
//  SelectTimeView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

struct SelectTimeView: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    
    @State private var hour: Int = 22
    @State private var minute: Int = 30
    
    @State private var selectedDay: Int? = nil
    
    var body: some View {
        
        DropDownMenu {
            
            dayPicker
            
            Divider()
            
            timePicker
        }
        .onAppear { syncWithEvent() }
    }
}

extension SelectTimeView {
    
    private var dayPicker: some View {
        
        let nextSevenDays: [Date] = {
            let calendar = Calendar.current
            let today = Date()
            return (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: today)
            }
        }()
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(0..<7) { idx in
                
                let day = nextSevenDays[idx]
                let today = Calendar.current.isDateInToday(day)
                
                
                VStack(spacing: 24) {
                    Text(day, format: .dateTime.weekday(.narrow))
                        .font(.body(12, .bold))
                    
                    Text(day, format: .dateTime.day())
                        .font(.body(18))
                        .foregroundStyle(today && selectedDay != idx ? .blue : .black)
                        .background (
                            Circle()
                                .fill(selectedDay == idx ? Color.accentColor.opacity(0.2) : .clear)
                                .frame(width: 40, height: 50)
                        )
                        .onTapGesture {
                            selectedDay = idx
                            var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
                            components.hour = hour
                            components.minute = minute
                            vm.event.time = Calendar.current.date(from: components)
                        }
                }
            }
        }
    }
    
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
        .onAppear {updateTime()}
    }
    
    private func updateTime() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: vm.event.time ?? Date())
        components.hour = hour
        components.minute = minute
        vm.event.time = Calendar.current.date(from: components)
    }
    
    private func syncWithEvent() {
        guard let date = vm.event.time else { return }

        let calendar = Calendar.current
        hour = calendar.component(.hour, from: date)
        minute = calendar.component(.minute, from: date)

        let startOfToday = calendar.startOfDay(for: Date())
        let startOfEvent = calendar.startOfDay(for: date)
        if let days = calendar.dateComponents([.day], from: startOfToday, to: startOfEvent).day,
           (0..<7).contains(days) {
            selectedDay = days
        }
    }
}


    
    
    
    

