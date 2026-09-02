//
//  SelectTimeContainer.swift
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
        VStack(spacing: 0) {
            titleSection
            dayPicker
                .padding(.top, isRespondMode ? Spacing.xxs : Spacing.md) //Respond mode: the parent supplies the title row, this is the page's top inset
            TimePicker(selectedHour: $selectedHour, selectedMinute: $selectedMinute)
                .padding(.top, Spacing.xxs) //The wheel's own top fade does the separating
        }
        .modifier(SelectTimeBackground(isRespondMode: isRespondMode))
        .overlay(alignment: .bottomTrailing) { TimeDoneButton(isRespondMode: isRespondMode) }
        .onChange(of: selectedTimeInMinutes) { updateTime() }
        .task(id: warning) { await clickedUnavailableDay() }
        .savedFeedback(isPresented: $showSaved, tracking: selectedTimeInMinutes)
    }
}

//Title row and the day picker
private extension SelectTimeView {
    
    //The day counter rides the title row as its trailing accessory: same margin, same baseline as "When".
    @ViewBuilder
    private var titleSection: some View {
        if !isRespondMode {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("When")
                        .font(.body(17, .medium))
                        .foregroundStyle(Color.textPrimary)
                    Text("Propose 1–3 days to meet")
                        .font(.body(13, .regular))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                DayCountAndWarning(showSaved: showSaved, warning: warning, dayCount: displayedCount)
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

//Propose mode owns its platter insets; respond mode's parent page applies them.
//No bottom inset: the wheel runs to the platter's edge and dissolves there (see TimePicker).
struct SelectTimeBackground: ViewModifier {

    let isRespondMode: Bool
    
    func body(content: Content) -> some View {
        if isRespondMode {
            content
        } else {
            content
                .padding(.horizontal, Spacing.margin)
                .padding(.top, Spacing.md)
        }
    }
}

//Used In RespondTime so put in struct
struct TimeDoneButton: View {
    
    @Environment(\.timeCustomMenuDismiss) private var dismissMenu

    static let size: CGFloat = 30
    
    var isRespondMode: Bool = false
    var body: some View {
            Button {
                dismissMenu()
            } label: {
                Image("WhiteTick")
                    .scaleEffect(1.1)
                    .frame(width: Self.size, height: Self.size)
                    .background(Color.accent, in: Circle())
            }
            .shrinkButton()
            .padding(.bottom, TimePicker.height / 2 - Self.size / 2) //Geometry: centred on the wheel's selected row — the value the tick confirms
            .padding(.horizontal, isRespondMode ? 0 : Spacing.margin)
    }
}
