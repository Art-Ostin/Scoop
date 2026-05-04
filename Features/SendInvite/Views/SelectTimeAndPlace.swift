import SwiftUI
import MapKit


struct SelectTimeAndPlace: View {
    //1. Controls what popup is showing or not
    @State private var ui = TimeAndPlaceUIState()

    //2. The draft holds, proposedTimes, message, time and place, modified in this view
    @Binding var draft: EventFieldsDraft
    
    //3. property to hide and show the popup
    @Binding var showInvite: String?
    
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
    
    var body: some View {
        ZStack {
            if !isInviteResponse {
                CustomScreenCover {showInvite = nil}
            }
            VStack(spacing: 0) {
                popupTitle
                VStack(spacing: 12) {
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
            .modifier(TimeAndPlaceCard(showInfoScreen: $ui.showInfoScreen, messageCount: draft.message?.count ?? 0, placeAdded: draft.place != nil))
            .customAlert(isPresented: $ui.showConfirmPopup, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "If they accept & you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) {onSendInvite()}
            .overlay(alignment: .topLeading) { clearButton }
            .offset(y: !isInviteResponse ? 24 : 0)
            .overlay(alignment: .top) {messageOverlay}
        }
        .hideTabBar()
        .fullScreenCover(isPresented: $ui.showMapView) {MapView(defaults: defaults, eventLocation: $draft.place)}
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
    }
}

extension SelectTimeAndPlace {

    @ViewBuilder private var clearButton: some View {
        if hasDraftChanges {
        Button {
                deleteEventDefault()
            } label: {
                Text("Clear")
                    .font(.body(12, .regular))
                    .foregroundStyle(Color (red: 0.7, green: 0.7, blue: 0.7))
                    .offset(x: -10, y: -8)
            }
            .padding(.top, 24)
            .padding(.horizontal, ((draft.message?.count ?? 0) > 35 || draft.place != nil) ? 28 : 32)
        }
    }
    
    private var popupTitle: some View {
        HStack(spacing: 8) {
            CirclePhoto(image: image, showShadow: false, height: 30)
            Text(isInviteResponse ? "Send New Invite" : "Meet \(name)")
                .font(.custom("SFProRounded-Bold", size: 24))
        }
    }
    
    private var sendInviteButton: some View {
        ActionButton(isValid: !ui.showConfirmPopup && InviteIsValid && !showTwoDays, text: "Send Invite", showShadow: false) {
            ui.showConfirmPopup = true
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
