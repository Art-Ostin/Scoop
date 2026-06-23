import SwiftUI


//Vertical spacing here is adaptive. Therefore, it is controlled by the type, time, place padding not the vertical stacks

struct SendInviteContainer: View {
    //0. Base gap from each screen edge to the card. Passed to the morph as the entrance-fallback
    //width (`style.sideMargin`) at the call sites. The live, adaptive margin is `cardMargin`,
    //which the card now owns directly via padding (content-owns-background morph).
    static let screenMargin: CGFloat = 30

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
                .opacity(ui.timePopupOpen ? 0.1 : 1)
                .animation(.snappy(duration: 0.2), value: ui.timePopupOpen)
            timePlaceAndType
            sendInviteButton
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) { clearAndInfoButtons }
        .modifier(InviteCardBackground())
        .padding(.horizontal, cardMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.top, 24)
        .animation(.spring(duration: 0.3), value: [Double(cardMargin), Double(ui.messageLineCount)])
        .task(id: ui.timePopupOpen) { await addTimePopupDelay() }
        .task(id: ui.typePopupOpen) { await addTypePopupDelay()}
        .morphPopupOpen(ui.timePopupOpenDelayed || ui.typePopupOpenDelayed) //hide the morph's floating Hide button while a popup is open

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
            InviteTimeRow(ui: ui, showTimePopup: ui.binding(for: .time), proposedTimes: $draft.time)
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
        NavigationStack {
            AddMessageView(message: $draft.message, isRespondMessage: false, eventType: $draft.type)
        }
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
