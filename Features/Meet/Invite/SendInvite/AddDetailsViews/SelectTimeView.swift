//
//  SelectTimeView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

struct SelectTimeView: View {
    
    //Updating a proposedTime
    @Binding var proposedTimes: ProposedTimes
    
    @State var clickedMax = false
    @Binding var showTimePopup: Bool
    @State private var shakeTicksByDay: [Date: Int] = [:]
    @State private var clickedUnavailbleDay = false
    @State private var selectedHour = 22
    @State private var selectedMinute = 30
    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayCount = 11
    var isRespondMode: Bool = false
        
    var body: some View {
        VStack(spacing: 12) {
            dayPicker
                .scaleEffect(isRespondMode ? 0.95 : 1)
            Divider()
                .padding(.horizontal, isRespondMode ? 16 : 0)
            timePicker
                .scaleEffect(isRespondMode ? 0.95 : 1)
                .offset(y: isRespondMode ? -10 : 0)
        }
        .frame(width: 280)
        .overlay(alignment: .bottomTrailing) {doneButton}
        .padding(.horizontal, isRespondMode ? 0 : 24)
        .padding(.top, isRespondMode ? 0 : 24)
        .padding(.bottom, isRespondMode ? -12 : 12)
        .background { if !isRespondMode {CardBackground(cornerRadius: 16)}}
        .onAppear { syncTimePickerIfNeeded() }
        .onChange(of: selectedHour) { proposedTimes.updateTime(hour: selectedHour, minute: selectedMinute) }
        .onChange(of: selectedMinute) { proposedTimes.updateTime(hour: selectedHour, minute: selectedMinute) }
        .onChange(of: proposedTimes.dates) { syncTimePickerIfNeeded()}
        .overlay(alignment: .top) {maxIcon}
        .task(id: clickedMax) {await clickedMaxFunc()}
        .task(id: clickedUnavailbleDay) {await clickedUnavailableDayFunc() }
        .animation(.easeInOut(duration: 0.2), value: clickedMax)
        .animation(.easeInOut(duration: 0.2), value: clickedUnavailbleDay)
//        .overlay(alignment: .top) { if isRespondMode{ infoSection}}
    }
}

//Views

extension SelectTimeView {
    
    private func clickedMaxFunc() async {
        guard clickedMax == true else {return}
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.easeInOut(duration: 0.2)) { clickedMax = false }
    }
    
    private func clickedUnavailableDayFunc() async {
        guard clickedUnavailbleDay == true else {return}
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.easeInOut(duration: 0.2)) { clickedUnavailbleDay = false }
    }
    
    @ViewBuilder
    private var infoSection: some View {
        Group {
            if clickedMax {
                Text("Max 3")
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.warningYellow)
            } else if clickedUnavailbleDay {
                Text("Day Unavailable")
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.warningYellow)
            } else {
                Text("Propose at least two days")
                    .font(.body(12, .regular))
                    .foregroundStyle(Color.grayText)
            }
        }
        .padding(.horizontal)
        .background(Color.background)
        .padding(.top, 98)
    }
    
    @ViewBuilder
    private var maxIcon: some View {
        if !isRespondMode {
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
    }
    
    private var days: [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfToday)
        }
    }
    
    private var dayPicker: some View {
        return LazyVGrid(columns: columns, spacing: isRespondMode ? 10 : 12) {
            ForEach(0..<7) {idx in
                Text(days[idx], format: .dateTime.weekday(.abbreviated))
                    .font(.body(12, isRespondMode ? .regular : .bold))
                    .foregroundStyle(isRespondMode ?  Color(red: 0.6, green: 0.6, blue: 0.6) : Color(red: 0.2, green: 0.2, blue: 0.2))
            }
            ForEach(days.indices, id: \.self) { idx in
                event(idx: idx)
            }
        }
    }
    
    private var doneButton: some View {
            ZStack {
                Image(isRespondMode ? "GreenTickMark" : "TickButton")
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
                    showTimePopup.toggle()
                }
            }
            .padding(.bottom, isRespondMode ? 96 : 80)
    }

    @ViewBuilder
    private func event(idx: Int) -> some View {
        let day = days[idx]
        let isToday = Calendar.current.isDateInToday(day)
        let isSelected = proposedTimes.contains(day: day)
        
        let keyDay = Calendar.current.startOfDay(for: day)
        let shakeValue = shakeTicksByDay[keyDay, default: 0]
        
        Button {
            if isToday {
                shakeTicksByDay[keyDay, default: 0] += 1
                clickedUnavailbleDay.toggle()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                let hitMax = proposedTimes.updateDate(day: day, hour: selectedHour, minute: selectedMinute)
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
            Picker("Hour", selection: $selectedHour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            
            Picker("Minute", selection: $selectedMinute) {
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
        guard let first = proposedTimes.dates.first else { return }
        let calendar = Calendar.current
        let newHour = calendar.component(.hour, from: first.date)
        let newMinute = calendar.component(.minute, from: first.date)
        if newHour != selectedHour || newMinute != selectedMinute {
            selectedHour = newHour
            selectedMinute = newMinute
        }
    }
}
