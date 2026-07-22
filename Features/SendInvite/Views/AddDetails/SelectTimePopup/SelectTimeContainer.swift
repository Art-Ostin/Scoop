//
//  SelectTimeView2.swift
//  Scoop
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

enum DayWarning: String { case maxReached = "Max 3", dayUnavailable = "Day Unavailable" }

struct SelectTimeView: View {

    //Injected
    @Binding var proposedTimes: ProposedTimes

    //Local view state
    @State private var selectedHour = 21
    @State private var selectedMinute = 30
    @State private var warning: DayWarning?
    
    //To Show Saved or not
    @State private var showSaved = false
    @State private var savedTask: Task<Void, Never>?
    @State private var suppressSavedFlash = false
    
    
    var displayedCount: Int {
        proposedTimes.dates.count
    }
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            titleSection
            dayPicker
                .padding(.top, Spacing.xxs)
            TimePicker(selectedHour: $selectedHour, selectedMinute: $selectedMinute)
                .padding(.top, -Spacing.xs)
        }
        .modifier(SelectTimeBackground())
        .overlay(alignment: .bottomTrailing) { TimeDoneButton()}
        .onAppear {loadTimeAndDayCount()}
        .onChange(of: selectedHour * 60 + selectedMinute) {updateTimeAndFlashSave()}
        .task(id: warning) { await clickedUnavailableDay() }
    }
}

//Title Logic and Done Button
private extension SelectTimeView {
    
    private var titleSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose Time") //"Propose up to 3 days"
                    .font(.body(17, .medium))
                    .foregroundStyle(Color.textPrimary)
                Text("Propose 1-3 days to meet")
                    .font(.body(11, .regular))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
        }
        .overlay(alignment: .topTrailing) {
            DayCountAndWarning(showSaved: showSaved, warning: warning, dayCount: displayedCount)
        }
    }
    
    private var dayPicker: some View {
        DayPicker(proposedTimes: $proposedTimes, dayWarning: $warning, selectedHour: selectedHour, selectedMinute: selectedMinute)
    }
}

private extension SelectTimeView {
    
    func clickedUnavailableDay() async {
        guard warning != nil else { return }
        try? await Task.sleep(for: .seconds(1))
        warning = nil
    }

    func updateTimeAndFlashSave() {
        proposedTimes.updateTime(hour: selectedHour, minute: selectedMinute)
        if suppressSavedFlash {
            suppressSavedFlash = false
        } else {
            flashSaved()
        }
    }
    
    func flashSaved() {
        savedTask?.cancel()
        savedTask = Task {
            if showSaved {
                withAnimation(.quick) { showSaved = false }
                try? await Task.sleep(for: .milliseconds(120))
                if Task.isCancelled { return }
            }
            withAnimation(.toggle) { showSaved = true }
            try? await Task.sleep(for: .milliseconds(1000))
            if Task.isCancelled { return }
            withAnimation(.toggle) { showSaved = false }
        }
    }

    func loadTimeAndDayCount() {
        guard let date = proposedTimes.dates.first?.date else { return }
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        if h != selectedHour || m != selectedMinute { suppressSavedFlash = true }
        selectedHour = h
        selectedMinute = m
    }
}

struct SelectTimeBackground: ViewModifier {

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.margin)
            .padding(.top, Spacing.md)
            .padding(.bottom, -Spacing.xs) //Low bottom as scroll view on Bottom
    }
}

//Used In RespondTime so put in struct
struct TimeDoneButton: View {
    
    @Environment(\.timeCustomMenuDismiss) private var dismissMenu
    
    var body: some View {
            Button {
                dismissMenu()
            } label: {
                Image("TickButton")
                    .scaleEffect(0.9)
                    .frame(width: 30, height: 30)
                    .circleStroke(lineWidth: 1, color: .black)
            }
            .shrinkButton()
            .padding(.bottom, Spacing.clearance - 14) //Positions it at top of time view
            .padding(.horizontal, Spacing.margin)
    }
}


