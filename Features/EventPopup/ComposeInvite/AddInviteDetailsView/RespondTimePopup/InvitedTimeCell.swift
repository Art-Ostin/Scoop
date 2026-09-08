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

    var body: some View {
        //A plain Button, not a ScoopButton: its tinted lens is drawn BEHIND the label, and the label
        //already paints an opaque white card at the same shape and radius — the glass never reached the
        //screen. What it did ship was a shadow no Elevation owns, and expandHitArea(16), which is exactly
        //the gap InvitedTimes leaves between cells: both neighbours claimed it, and the lower one won.
        Button {
            clickCell()
        } label: {
            timeCellLabel
        }
        .subtleShrinkButton() //a card this wide only needs a hint of travel; the full shrink dims it like a scrim
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : []) //selection is carried by colour alone otherwise
        .sensoryFeedback(.selection, trigger: selectionTick) // the accepted tap's tick, as the day cell gives
        .sensoryFeedback(.warning, trigger: shake)   // the refusal at an unavailable slot, as the day cap gives
        //Keyed on the toggling flag, not on `isShaking`: a second refusal leaves `isShaking` already
        //true, so an id of `isShaking` would never re-run and the flash would end on the first tap's clock.
        .task(id: shake) {await resetShakeFlag()}
    }
}

extension InvitedTimeCell {
    
    private var timeCellLabel: some View {
        HStack(spacing: Spacing.md) {
            selectedIcon(isSelected: isSelected)
            VStack(alignment: .leading, spacing: Spacing.labelGap) {
                //The status is a member of this line rather than an overlay on the card's corner: it
                //shares the option label's baseline, and can never grow back over the text column.
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    optionTypeText
                    Spacer(minLength: 0)
                    timeStatusText
                }
                eventTimeText
            }
        }
        .invitedTimeCellBackground(isSelected: isSelected)
        .animation(.selectionDot, value: isSelected) //ring, dot, card stroke and label all land together
        .showShakeAnimation(bool: shake, amplitude: 1.4)
        //A full-width card needs a wider swing than the day dot to read as a refusal
    }
    
    //Geometry: the ring at the size it is drawn, not a 25pt box scaled to 20. A scaleEffect resamples
    //circleStroke's pixel-snapped hairline — the uneven fringe that helper exists to prevent — and it
    //left 2.5pt of dead layout each side, so the gap the HStack asked for was never the gap on screen.
    private static let ringSize: CGFloat = 20
    private static let ringDot: CGFloat = 10   //Geometry: half the ring — the filled core of a radio
    private static let ringStroke: CGFloat = 1.2 //Geometry: what 1.5 scaled by 0.8 already composited to

    private func selectedIcon(isSelected: Bool) -> some View {
        Color.clear //not a bare Circle(): a Shape used as a View fills with whatever foreground it inherits
            .frame(width: Self.ringSize, height: Self.ringSize)
            //Resting, the ring shares the card's own rule; selected, ring and dot take .accent — the
            //fill/control tone the card stroke already wears. textAccent is for accent-coloured type.
            .circleStroke(lineWidth: Self.ringStroke, color: isSelected ? Color.accent : Color.borderLight)
            .overlay {
                //Always mounted and grown in place, as the day cell's dot is — an `if` is an insertion,
                //and no ancestor animation can drive one.
                Circle()
                    .fill(Color.accent)
                    .frame(width: Self.ringDot, height: Self.ringDot)
                    .scaleEffect(isSelected ? 1 : 0.30) //the day cell's own 0.30↔1
                    .opacity(isSelected ? 1 : 0)
            }
    }
        
    private var optionTypeText: some View {
        //13, the app's label rung — the platter's subtitle, its toggle and this cell's own status word
        //all sit there. At 15 its cap height is 88% of the value line's and it read as a second value.
        Text("Option \(idx + 1)")
            .font(.body(13, .medium))
            .foregroundStyle(isSelected ? Color.textAccent : Color.textTertiary)
    }
    
    //FormatEvent, not an inline template: the template spells "Sat, Sep 12" while the row this platter
    //closes onto draws FormatEvent's own "Sat Sep 12" — one tap left two different strings on screen.
    //The hour keeps its own 15pt step below the day, so size carries the hierarchy and colour seconds it.
    //The dim is a token rung rather than an opacity multiplier, which drove the hour under
    //textPlaceholder — and the weight holds still, because here weight moves for selection, not state.
    private var eventTimeText: some View {
        let live = status == .available
        return (
            Text(FormatEvent.shortDayAndTime(date, withHour: false))
                .font(.body(17, .medium))
                .foregroundStyle(live ? Color.textPrimary : Color.textSecondary)
            +
            Text(" · \(FormatEvent.hourTime(date))")
                .font(.body(15))
                .foregroundStyle(live ? Color.textTertiary : Color.textPlaceholder)
        )
        .oneLineLimitAndShrink() //a long locale shrinks rather than wraps, as the destination row does
    }
    
    @ViewBuilder
    private var timeStatusText: some View {
        if status != .available {
            //13 medium, the same rung and face as the option label it shares a baseline with. Not
            //italic: `.italic` is a Medium face, so the marker for a dead row outweighed the row.
            Text(status.rawValue.capitalized)
                .font(.body(13, .medium))
                .foregroundStyle(isShaking ? Color.warningYellow : Color.textTertiary)
                .animation(.transition, value: isShaking)
                .fixedSize() //the option label gives when the line is tight, never the reason
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
        //do/catch rather than try?: a second refusal cancels this task, and swallowing the cancellation
        //would run the next line and switch off the flash the new tap has just turned on.
        do { try await Task.sleep(for: .seconds(1)) } catch { return }
        withAnimation(.transition) { isShaking = false }
    }
}

//The cell's own card: an opaque white plate on the platter's glass, stroked at the same radius.
//private — it was module-wide API for one cell in one folder.
private extension View {
    func invitedTimeCellBackground(isSelected: Bool) -> some View {
        self
            //Stretched before it is padded, so a trailing member of the row lands on the card's own
            //inner edge instead of hugging the text beside it.
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            //Geometry: the height the card stood at before the label came down a rung and the two
            //lines tightened — 15 + 8 + 17 of ModernEra inside this 12pt padding. Pinned rather than
            //recovered from the type, so the stack of three keeps the rhythm it was measured at.
            .frame(minHeight: invitedTimeCellHeight)
            .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
            .stroke(CornerRadius.md, color: isSelected ? Color.accent : Color.borderLight)
            .contentShape(.rect(cornerRadius: CornerRadius.md)) //the tap follows the card; ScoopButton's shape went with it
    }
}

private let invitedTimeCellHeight: CGFloat = 64
