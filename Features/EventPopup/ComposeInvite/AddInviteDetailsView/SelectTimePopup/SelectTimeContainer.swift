//
//  SelectTimeContainer.swift
//  Scoop
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

enum DayWarning: String { case maxReached = "Max 3", dayUnavailable = "Day Unavailable" }

struct SelectTimeView: View {

    static let platterWidth: CGFloat = 346

    static let columnInset: CGFloat = (platterWidth - DayCell.gridWidth) / 2

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
                .padding(.top, isRespondMode ? Spacing.sm : Spacing.lg)
            TimePicker(selectedHour: $selectedHour, selectedMinute: $selectedMinute)
                .padding (.top, Spacing.xxs) //The wheel's own top fade does the separating
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
                        .font(.body(18, .medium))
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
                .padding(.horizontal, SelectTimeView.columnInset)
                .padding(.top, Spacing.lg) //the platter's top air, a step over the content's own rhythm
        }
    }
}

//Used In RespondTime so put in struct
struct TimeDoneButton: View {
    
    @Environment(\.timeCustomMenuDismiss) private var dismissMenu
    
    static let size: CGFloat = 35 //Geometry: pairs with the 32pt day dot
    
    var isRespondMode: Bool = false
    var body: some View {
        ScoopButton(style: .tinted(.textAccent, shadow: nil, glass: true), shape: Circle(), size: .medium) {
            dismissMenu()
        } label: {
            Image("WhiteTick")
                .resizable()
                .scaledToFit()
                .scaleEffect(0.5)
        }
        .shrinkButton()
        .padding(.bottom, TimePicker.height / 2 - Self.size / 2)
        .padding(.horizontal, isRespondMode ? 0 : SelectTimeView.columnInset)
        .offset(y: -32)
    }
}
