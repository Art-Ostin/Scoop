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
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var warning: DayWarning?
    @State private var showSaved = false
    let isRespondMode: Bool

    init(
        proposedTimes: Binding<ProposedTimes>,
        isRespondMode: Bool = false
    ) {
        _proposedTimes = proposedTimes
        self.isRespondMode = isRespondMode

        let components = proposedTimes.wrappedValue.dates.first.map {
            Calendar.current.dateComponents([.hour, .minute], from: $0.date)
        }
        _selectedHour = State(initialValue: components?.hour ?? 21)
        _selectedMinute = State(initialValue: components?.minute ?? 30)
    }

    private var selectedTimeInMinutes: Int {
        selectedHour * 60 + selectedMinute
    }

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
        .modifier(SelectTimeBackground(isRespondMode: isRespondMode))
        .overlay(alignment: .bottomTrailing) { TimeDoneButton(isRespondMode: isRespondMode)}
        .onChange(of: selectedTimeInMinutes) { updateTime() }
        .task(id: warning) { await clickedUnavailableDay() }
        .savedFeedback(isPresented: $showSaved, tracking: selectedTimeInMinutes)
        .overlay(alignment: isRespondMode ? .bottomLeading : .topTrailing) {
            DayCountAndWarning(showSaved: showSaved, warning: warning, dayCount: displayedCount)
                .padding()
                .padding(.horizontal, isRespondMode ? -24 : 0)//Avoids double counting
        }
    }
}

//Title Logic and Done Button
private extension SelectTimeView {
    
    @ViewBuilder
    private var titleSection: some View {
        if !isRespondMode {
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

    func updateTime() {
        proposedTimes.updateTime(hour: selectedHour, minute: selectedMinute)
    }
}

struct SelectTimeBackground: ViewModifier {

    let isRespondMode: Bool
    
    func body(content: Content) -> some View {
        if isRespondMode {
            content
        } else {
            content
                .padding(.horizontal, Spacing.margin)
                .padding(.top, Spacing.md)
                .padding(.bottom, -Spacing.xs) //Low bottom as scroll view on Bottom
        }
    }
}

//Used In RespondTime so put in struct
struct TimeDoneButton: View {
    
    @Environment(\.timeCustomMenuDismiss) private var dismissMenu
    
    var isRespondMode: Bool = false
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
            .padding(.horizontal, isRespondMode ? 0 :  Spacing.margin)
        
    }
}
