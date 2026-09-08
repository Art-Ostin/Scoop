//
//  InvitedTimeCell.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.

import SwiftUI

struct InvitedTimeCell: View {

    //Injected
    @Environment(\.timeCustomMenuDismiss) private var dismissMenu
    @Binding var selectedDay: Date?
    @Binding var responseType: ResponseType
    let status: TimeStatus
    let date: Date
    let idx: Int

    //Local view state
    @State private var shake = false        // toggled to fire a shake
    @State private var isShaking = false    // true while the warning text flashes yellow
    @State private var selectionTick = 0    // bumps once per accepted tap, so only an accept clicks

    private var isSelected: Bool { selectedDay == date }
    
    let inactiveColour: Color = Color(red: 0.8, green: 0.79, blue: 0.78)

    var body: some View {
        Button {
            clickCell()
        } label: {
            timeCellLabel
        }
        .subtleShrinkButton() //a card this wide only needs a hint of travel; the full shrink dims it like a scrim
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .sensoryFeedback(.selection, trigger: selectionTick)
        .sensoryFeedback(.warning, trigger: shake)
        .task(id: shake) {await resetShakeFlag()}
    }
}

extension InvitedTimeCell {
    
    private var timeCellLabel: some View {
        HStack(spacing: Spacing.md) {
            selectedIcon(isSelected: isSelected)
            VStack(alignment: .leading, spacing: Spacing.labelGap) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    optionTypeText
                    Spacer(minLength: 0)
                    timeStatusText
                }
                eventTimeText
            }
        }
        .invitedTimeCellBackground(isSelected: isSelected, isActive: status == .available)
        .animation(.selectionDot, value: isSelected) //ring, dot, card stroke and label all land together
        .showShakeAnimation(bool: shake, amplitude: 1.4)
    }
    
    private static let ringSize: CGFloat = 20
    private static let ringDot: CGFloat = 10   //Geometry: half the ring — the filled core of a radio
    private static let ringStroke: CGFloat = 1.2 //Geometry: what 1.5 scaled by 0.8 already composited to

    private func selectedIcon(isSelected: Bool) -> some View {
        Color.clear //not a bare Circle(): a Shape used as a View fills with whatever foreground it inherits
            .frame(width: Self.ringSize, height: Self.ringSize)
            .circleStroke(lineWidth: Self.ringStroke, color: isSelected ? Color.accent : Color.borderLight)
            .overlay {
                Circle()
                    .fill(Color.accent)
                    .frame(width: Self.ringDot, height: Self.ringDot)
                    .scaleEffect(isSelected ? 1 : 0.30)
                    .opacity(isSelected ? 1 : 0)
            }
    }
        
    private var optionTypeText: some View {
        Text("Option \(idx + 1)")
            .font(.body(13, .medium))
            .foregroundStyle(isSelected ? Color.textAccent : status == .available ? Color.textTertiary : Color.textPlaceholder)
    }
    
    private var eventTimeText: some View {
        let live = status == .available
        return (
            Text(FormatEvent.shortDayAndTime(date, withHour: false))
                .font(.body(17,  live ? .medium : .regular))
                .foregroundStyle(live ? Color.textPrimary : inactiveColour)
            +
            Text(" · \(FormatEvent.hourTime(date))")
                .font(.body(15, live ? .medium : .regular))
                .foregroundStyle(live ? Color.textTertiary : inactiveColour)
        )
        .oneLineLimitAndShrink()
    }
    
    @ViewBuilder
    private var timeStatusText: some View {
        if status != .available {
            Text(status.rawValue.capitalized)
                .font(.body(13, .medium))
                .foregroundStyle(isShaking ? Color.warningYellow : Color.textTertiary)
                .animation(.transition, value: isShaking)
                .fixedSize()
        }
    }

    //VoiceOver reads the ordinal, the day spelled out and the state; the flattened default says "middle dot".
    private var accessibilityText: String {
        let when = date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        let base = "Option \(idx + 1), \(when) at \(FormatEvent.hourTime(date))"
        return status == .available ? base : "\(base), \(status.rawValue)"
    }
}

//Logic for clicking a time
extension InvitedTimeCell {
    
    private func clickCell() {
        guard checkIfTimeIsAvailable() else { return}
        updateTimeAndDismissPopup()
    }
    
    private func checkIfTimeIsAvailable() -> Bool {
        guard status == .available else {
            shake.toggle()
            isShaking = true
            return false
        }
        return true
    }
    
    private func updateTimeAndDismissPopup() {
        selectedDay = date
        responseType = .originalInvite
        selectionTick += 1 //only an accepted tap clicks; a refusal has its own warning haptic
        dismissMenu()
    }
    
    private func resetShakeFlag()  async  {
        guard isShaking else { return }
        do { try await Task.sleep(for: .seconds(1)) } catch { return }
        withAnimation(.transition) { isShaking = false }
    }
}

private extension View {
    func invitedTimeCellBackground(isSelected: Bool, isActive: Bool) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: invitedTimeCellHeight)
            .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
            .stroke(CornerRadius.md, color: isSelected ? Color.accent : isActive ? Color.borderLight: Color.borderLight.opacity(isActive ? 0.9 : 1) )
            .contentShape(.rect(cornerRadius: CornerRadius.md)) //the tap follows the card; ScoopButton's shape went with it
    }
}

private let invitedTimeCellHeight: CGFloat = 64
