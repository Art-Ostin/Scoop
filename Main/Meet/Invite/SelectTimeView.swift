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
    
    let columns: [GridItem] =  Array(repeating: GridItem(.flexible()), count: 7)

    
    let dayCount = 11 //Meet up, up to 10 days in future, not including today
    
    var body: some View {
        
        DropDownMenu(cornerRadius: 16) {
            
            dayPicker
            
            Divider()
            
            timePicker
        }
        .onAppear { syncWithEvent() }
        
    }
}

extension SelectTimeView {
    
    private var dayPicker: some View {
        
        let nextElevenDays: [Date] = {
            let calendar = Calendar.current
            let today = Date()
            return (0..<dayCount).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: today)
            }
        }()
        
        return LazyVGrid(columns: columns, spacing: 24) {
            
                //First lay out the days of the week at top then all the days
                ForEach(0..<7) { idx in
                    Text(nextElevenDays[idx], format: .dateTime.weekday(.narrow))
                        .font(.body(12, .bold))
                }
                
                ForEach(nextElevenDays.indices, id: \.self) { idx in
                    event(day: nextElevenDays[idx], idx: idx)
            }
        }
    }
    
    @ViewBuilder
    private func event(day: Date, idx: Int) -> some View {
        let isToday = Calendar.current.isDateInToday(day)
        
        let isSelected = selectedDay == idx
        
        Text(day, format: .dateTime.day())
            .font(.body(18))
            .foregroundStyle(isToday ? Color.grayPlaceholder : (isSelected ? Color.accent : .black))
            .background(
                Circle()
                    .stroke(100, lineWidth: 1, color: isSelected ? .accent : .clear)
            )
            .onTapGesture {
                selectedDay = idx
                var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
                components.hour = hour
                components.minute = minute
                vm.event.time = Calendar.current.date(from: components)
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


    
    
/*
 ForEach(nextElevenDays.indices, id: \.self) { idx in
     
     let day = nextElevenDays[idx]
     let today = Calendar.current.isDateInToday(day)
     
     
     VStack(spacing: 24) {
         Text(day, format: .dateTime.weekday(.narrow))
             .font(.body(12, .bold))
         
         Group {
             Text(day, format: .dateTime.day())
             
             Text(day, format: .dateTime.day())
                 .padding(.top, 6)
         }
     }
 }
 */
    
    


