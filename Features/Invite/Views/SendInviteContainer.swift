import SwiftUI


//Vertical spacing here is adaptive. Therefore, it is controlled by the type, time, place padding not the vertical stacks

struct SendInviteContainer: View {
    //0. Base gap from each screen edge to the card. Passed to the morph as the entrance-fallback
    //width (`style.sideMargin`) at the call sites. The live, adaptive margin is `cardMargin`,
    //which the card now owns directly via padding (content-owns-background morph).
    static let screenMargin: CGFloat = 28

    //1. Controls what popup is showing or not
    @State var ui = TimeAndPlaceUIState()

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


    var body: some View {
        VStack(spacing: 0) {
            inviteTitle
            timePlaceAndType
            sendInviteButton
        }
        .frame(maxWidth: .infinity)                 //stretch the card out to its margin-inset width
        .overlay(alignment: .topTrailing) { clearAndInfoButtons }
        .modifier(InviteCardBackground())            //draws the card chrome + publishes morphCardAnchor
        .padding(.horizontal, cardMargin)            //the screen margin, owned here and adaptive to content
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) //center in the morph's full-screen frame
        .padding(.top, 24)                           //small downward lift, matching the morph's old verticalOffset
        //One spring drives every adaptive change together: the card width (cardMargin) and the
        //rows' vertical padding (messageLineCount, which can change height without changing margin).
        .animation(.spring(duration: 0.3), value: [Double(cardMargin), Double(ui.messageLineCount)])
        .task(id: ui.popupOpen) { await addPopupDelay() }

        //All Logic of what screen to show and where
        .hideTabBar(hideBar: isInviteResponse)
        .respondCustomAlert(isPresented: $ui.showConfirmPopup, type: .newInvite) {onSendInvite()}
        .fullScreenCover(isPresented: $ui.showMapView) {MapView(defaults: defaults, eventLocation: $draft.place)}
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
    }
}

//Key Components
extension SendInviteContainer {
    //1. Main Views
    private var inviteTitle: some View {
        HStack(spacing: 8) {
            CirclePhoto(image: image, showShadow: false, height: 30)
            Text(isInviteResponse ? "Send New Invite" : "Meet \(name)")
                .font(.title(24))
        }
    }

    private var timePlaceAndType: some View {
        VStack(spacing: 0) {
            InviteTypeRow(ui: ui, type: $draft.type, unparsedMessage: $draft.message)
                .padding(.top, typeTopPadding)
                .padding(.bottom, typeBottomPadding)
            LightDivider()
            InviteTimeRow(ui: ui, showTimePopup: ui.binding(for: .time), proposedTimes: $draft.time, type: draft.type)
                .padding(.top, timeTopPadding)
                .padding(.bottom, timeBottomPadding)
            LightDivider()
            InvitePlaceRow(ui: ui, eventLocation: $draft.place, showMapView: $ui.showMapView, isMultipleTimes: draft.time.dates.count > 1)
                .padding(.top, placeTopPadding)
                .padding(.bottom, placeBottomPadding)
        }
        .zIndex(1) //so pop ups always appear above the Action Button
    }
    
    private var addMessageView: some View {
        AddMessageView(
            eventType: $draft.type,
            showMessageScreen: $ui.showMessageScreen,
            message: $draft.message,
            isRespondMessage: false
        )
    }
}


struct InviteCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .inviteCardBackground()
    }
}
