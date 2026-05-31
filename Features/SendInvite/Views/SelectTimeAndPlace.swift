import SwiftUI
import MapKit


struct SelectTimeAndPlace: View {
    //1. Controls what popup is showing or not
    @State private var ui = TimeAndPlaceUIState()

    //2. The draft holds, proposedTimes, message, time and place, modified in this view
    @Binding var draft: EventFieldsDraft

    //4. Info required for viewLayout
    let name: String
    let image: UIImage

    //5.Two different functions can be performed from this view
    let deleteEventDefault: () -> Void
    let onSendInvite: () -> ()
    
    //6. Layout differences if sending a new Invite as response
    let isInviteResponse: Bool
    
    //7.defaults only to pass into the MapView beneath
    let defaults: DefaultsManaging

    var requestConfirm: ((@escaping () -> Void) -> Void)? = nil

    //9. Vertical lift applied to the card in every mode (negative = up)
    private let cardLift: CGFloat = -36

    var body: some View {
        ZStack {
            VStack(spacing: isInviteResponse ? 48 : 0) {
                VStack(spacing: 0) {
                    popupTitle
                    VStack(spacing: 16) {
                        InviteTypeRow(ui: ui, eventType: $draft.type, unparsedMessage: $draft.message)
                        MapDivider()
                        InviteTimeRow(showTimePopup: ui.binding(for: .time), proposedTimes: $draft.time, type: draft.type)
                        MapDivider()
                        InvitePlaceRow(eventLocation: $draft.place, showMapView: $ui.showMapView)
                    }
                    .padding(.top, verticalPadding)
                    .padding(.bottom, extraBottomPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .zIndex(1) //so pop ups always appear above the Action Button
                    sendInviteButton
                }
                .timeAndPlaceCard(messageCount: draft.message?.count ?? 0, placeAdded: (draft.place != nil), morphMode: !isInviteResponse)
                .overlay(alignment: .topLeading) { clearButton }
                .overlay(alignment: .top) {messageOverlay}
                .offset(y: isInviteResponse ? cardLift : 0)
            }
        }
        .hideTabBar(hideBar: isInviteResponse)
        .respondCustomAlert(isPresented: $ui.showConfirmPopup, type: .newInvite) {onSendInvite()}
        .fullScreenCover(isPresented: $ui.showMapView) {MapView(defaults: defaults, eventLocation: $draft.place)}
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
    }
}

extension SelectTimeAndPlace {

    @ViewBuilder private var clearButton: some View {
        HStack {
            Button {
                    deleteEventDefault()
                } label: {
                    Text("Clear")
                        .font(.body(12, .regular))
                        .foregroundStyle(Color (red: 0.8, green: 0.8, blue: 0.8))
                }
            Spacer()
            
            Button {
                ui.showInfoScreen.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.body(12, .medium))
                    .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
            }
        }
        .offset(y: -8)
        .padding(.horizontal, 8)
        .padding(.top, 24)
        .padding(.horizontal, (((draft.message?.count ?? 0) > 35 || draft.place != nil) ? 36 : 42) - (isInviteResponse ? 0 : 24))
    }
    
    private var popupTitle: some View {
        HStack(spacing: 8) {
            CirclePhoto(image: image, showShadow: false, height: 30)
            Text(isInviteResponse ? "Send New Invite" : "Meet \(name)")
                .font(.custom("SFProRounded-Bold", size: 24))
        }
    }
    
    private var sendInviteButton: some View {
        ActionButton(text: "Send Invite", isValid: !ui.showConfirmPopup && InviteIsValid && !showTwoDays, showShadow: false) {
            if let requestConfirm {
                requestConfirm(onSendInvite)
            } else {
                ui.showConfirmPopup = true
            }
        }
    }
        
    private var addMessageView: some View {
        AddMessageView(
            eventType: $draft.type,
            showMessageScreen: $ui.showMessageScreen,
            message: $draft.message,
            isRespondMessage: false
        )
    }
    
    private var messageOverlay: some View {
        let dayCount = draft.time.dates.count
        return SelectTimeMessage(type: draft.type, dayCount: dayCount, showTimePopup: ui.activePopup == .time, isCardMessage: true)
    }

    private var showTwoDays: Bool {
        (draft.type == .drink || draft.type == .doubleDate) &&
        ui.activePopup != .type &&
        ((ui.activePopup == .time && draft.time.dates.count < 2) || draft.time.dates.count == 1)
    }

    private var hasDraftChanges: Bool {
        !draft.time.dates.isEmpty || draft.place != nil || draft.type != .drink || draft.message != nil
    }
    
    private var InviteIsValid: Bool {
        !draft.time.dates.isEmpty && draft.place != nil
    }
    //Padding On bottom
    private var extraBottomPadding: CGFloat {
        return (draft.place != nil) ? decreaseVerticalPadding ? 16  : 24 : (decreaseVerticalPadding ? 16 : 18) //Works for complex reasons
    }
    private var verticalPadding: CGFloat {
        decreaseVerticalPadding ? 16 : 24
    }
    private var decreaseVerticalPadding: Bool {
        return (draft.message?.count ?? 0) > 40 && draft.place != nil
    }
}

struct HidePopup: View {

    let onHide: () -> Void

    var body: some View {
        Button(action: onHide) {
            Text("Hide")
                .font(.title(14, .bold))
                .kerning(1.5)
                .foregroundStyle(Color.black)
                .padding(36)
                .contentShape(Rectangle())
        }
        .padding(-36)
    }
}
