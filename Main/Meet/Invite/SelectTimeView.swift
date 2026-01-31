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
    let availableHours = [17, 18, 19, 20, 21, 22, 23, 00, 01, 02]
    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayCount = 11 //Meet up, up to 10 days in future, not including today
    
    var body: some View {
        DropDownMenu(cornerRadius: 16) {
            VStack(spacing: 12) {
                dayPicker
                Divider()
                timePicker
            }
        }
    }
}

//Views
extension SelectTimeView {
    
    private var days: [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfToday)
        }
    }
    
    private var dayPicker: some View {
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<7) {idx in
                Text(days[idx], format: .dateTime.weekday(.narrow))
                    .font(.body(12, .bold))
            }
            ForEach(days.indices, id: \.self) { idx in
                event(idx: idx)
            }
        }
    }

    @ViewBuilder
    private func event(idx: Int) -> some View {
        let day = days[idx]
        let isToday = Calendar.current.isDateInToday(day)
        let isSelected = selectedDay == idx
        Button {
            vm.event.proposedTimes.toggle(
                
            )
            
            
            
        } label : {
            Text(day, format: .dateTime.day())
                .font(.body(18, isSelected ? .bold : .medium))
                .foregroundStyle(isToday ? Color.grayPlaceholder : .black)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .foregroundStyle(isSelected ? Color.accent.opacity(0.2) : Color.clear)
                )
                .contentShape(.rect)
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
                ForEach([00, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 160, height: 130)
        .labelsHidden()
        .tint(.appRed)
        .accentColor(.appRed)
    }
    
    private func updateTime() {
        let calendar = Calendar.current
        let baseDate: Date = {
            guard let selectedDay else { return vm.event.time ?? Date()}
            return days[selectedDay]
        }()
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        vm.event.time = calendar.date(from: components)
    }
    
    
    Calendar.current

}

//Functions


/*
 
 extension SelectTimeView {
     
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
     
     private func updateTime() {
         let calendar = Calendar.current
         let baseDate: Date = {
             guard let selectedDay else { return vm.event.time ?? Date()}
             return days[selectedDay]
         }()
         var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
         components.hour = hour
         components.minute = minute
         vm.event.time = calendar.date(from: components)
     }
 }

 
 .onAppear { syncWithEvent() ; updateTime()}
 .onChange(of: hour) {updateTime()}
 .onChange(of: minute) {updateTime()}
 .onChange(of: selectedDay) { updateTime()}
 
 
 */
