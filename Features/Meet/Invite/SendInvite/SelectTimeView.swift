//
//  SelectTimeView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI
import Foundation

struct SelectTimeView: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    @State var clickedMax = false
    @Binding var showTimePopup: Bool
    @State private var shakeTicksByDay: [Date: Int] = [:]
    @State private var clickedUnavailbleDay = false

    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayCount = 11
    
    var body: some View {
        DropDownMenu(cornerRadius: 16) {
            ZStack {
                VStack(spacing: 12) {
                    dayPicker
                    Divider()
                    timePicker
                }
                doneButton
                    .position(x: 260, y: 140)
            }
        }
        .onAppear { syncTimePickerIfNeeded() }
        .onChange(of: vm.selectedHour) {vm.event.proposedTimes.updateTime(hour: vm.selectedHour, minute: vm.selectedMinute) }
        .onChange(of: vm.selectedMinute) {vm.event.proposedTimes.updateTime(hour: vm.selectedHour, minute: vm.selectedMinute) }
        .onChange(of: vm.event.proposedTimes.dates) { syncTimePickerIfNeeded()}
        .overlay(alignment: .top) {
            Group {
                if clickedMax {
                    Text("Max 3")
                } else if clickedUnavailbleDay {
                    Text("Day Unavailable")
                }
            }
            .font(.body(12, .bold))
            .foregroundStyle(Color.warningYellow)
            .offset(y: -18)
        }
        .task(id: clickedMax) {
            guard clickedMax == true else {return}
            try? await Task.sleep(for: .seconds(1))
            clickedMax = false
        }
        .task(id: clickedUnavailbleDay) {
            guard clickedUnavailbleDay == true else {return}
            try? await Task.sleep(for: .seconds(1))
            clickedUnavailbleDay = false
        }
        .animation(.easeInOut(duration: 0.2), value: clickedMax)
        .animation(.easeInOut(duration: 0.2), value: clickedUnavailbleDay)
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
                Text(days[idx], format: .dateTime.weekday(.abbreviated))
                    .font(.body(12, .bold))
            }
            ForEach(days.indices, id: \.self) { idx in
                event(idx: idx)
            }
        }
    }
    
    private var doneButton: some View {
        
            ZStack {
                Image("TickButton")
                    .scaleEffect(0.9)
                Circle()
                    .stroke(Color.black, lineWidth: 1)
                    .scaleEffect(0.8)
            }
            .padding(3)                 // hit area / breathing room
            .background(Color.background)
            .frame(width: 40, height: 40)
            .contentShape(Circle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    vm.showTimePopup.toggle()
                }
            }
    }

    @ViewBuilder
    private func event(idx: Int) -> some View {
        let day = days[idx]
        let isToday = Calendar.current.isDateInToday(day)
        let isSelected = vm.event.proposedTimes.contains(day: day)
        
        
        let keyDay = Calendar.current.startOfDay(for: day)
        let shakeValue = shakeTicksByDay[keyDay, default: 0]
        
        
        Button {
            if isToday {
                shakeTicksByDay[keyDay, default: 0] += 1
                clickedUnavailbleDay.toggle()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                let hitMax = vm.event.proposedTimes.updateDate(day: day, hour: vm.selectedHour, minute: vm.selectedMinute)
                if hitMax {
                    shakeTicksByDay[keyDay, default: 0] += 1   // <- triggers shake
                    clickedMax.toggle()
                }
            }
            }label: {
            Text(day, format: .dateTime.day())
                .font(.body(18, isSelected ? .bold : .medium))
                .foregroundStyle(isToday ? Color.grayPlaceholder : isSelected ? .accent : .black)
                .frame(width: 30, height: 30)
                .background(
                       Circle()
                        .offset(y: -1)
                        .strokeBorder(.black, lineWidth: isSelected ? 1 : 0)
                        .transaction { $0.animation = .linear(duration: 0.03) }
                )
                .contentShape(.rect)
        }
        .modifier(Shake(animatableData: shakeValue == 0 ? 0 : CGFloat(shakeValue)))
        .animation(shakeValue > 0 ? .easeInOut(duration: 0.5) : .none, value: shakeValue)
        .task(id: shakeValue) {
            guard shakeValue > 0 else { return }
            let captured = shakeValue
            try? await Task.sleep(for: .seconds(1))
            if shakeTicksByDay[keyDay, default: 0] == captured {
                withAnimation { shakeTicksByDay[keyDay] = 0 } // stop shaking
            }
        }
    }
    
    private var timePicker: some View {
        HStack {
            Picker("Hour", selection: $vm.selectedHour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            
            Picker("Minute", selection: $vm.selectedMinute) {
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
    
    private func syncTimePickerIfNeeded() {
        guard let first = vm.event.proposedTimes.dates.first else { return }
        let calendar = Calendar.current
        let newHour = calendar.component(.hour, from: first.date)
        let newMinute = calendar.component(.minute, from: first.date)
        if newHour != vm.selectedHour || newMinute != vm.selectedMinute {
            vm.selectedHour = newHour
            vm.selectedMinute = newMinute
        }
    }
}

/*
 if let clicked = clickedMax {
     if clicked == true {

 */
