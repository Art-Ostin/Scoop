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

    //8. Profile's send branch still hoists its confirm to the host (until Profile migrates).
    var requestConfirm: ((@escaping () -> Void) -> Void)? = nil

    //9. When provided, this card is the top-level morph card (standalone send): it owns its
    //   Hide control and fades itself behind the confirm alert — the morph no longer does
    //   either. Nil when embedded (e.g. the respond counter-invite page), where the parent
    //   owns the chrome and visibility.
    var onHide: (() -> Void)? = nil

    //Local space + measured card bottom, so the Hide control floats just below the card
    //(matches RespondContainer's own hide button).
    static let coordinateSpace = "SendInviteSpace"
    @State private var cardBottomY: CGFloat = 0

    private var ownsChrome: Bool { onHide != nil }

    var body: some View {
        ZStack(alignment: .top) {
            cardBody
                .getBottom(coordinateSpace: Self.coordinateSpace, bottom: $cardBottomY)

            if let onHide {
                HidePopup(onHide: onHide)
                    .offset(y: cardBottomY + 96) //Float the Hide control 96pt below the card bottom
                    .opacity(ui.timePopupOpenDelayed || ui.typePopupOpenDelayed ? 0 : 1) //gone while an inner picker is open
                    .animation(.easeInOut(duration: 0.2), value: ui.timePopupOpenDelayed)
            }
        }
        .coordinateSpace(.named(Self.coordinateSpace))
        //Standalone card fades itself behind the confirm alert (same easing the morph's old
        //hideCard used); embedded card leaves hiding to its parent.
        .opacity(ownsChrome && ui.showConfirmPopup ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: ui.showConfirmPopup)

        //All Logic of what screen to show and where. The confirm alert sits OUTSIDE the fade
        //above so it stays visible while the card hides behind it.
        .respondCustomAlert(isPresented: $ui.showConfirmPopup, type: .newInvite) {onSendInvite()}
        .fullScreenCover(isPresented: $ui.showMapView) {MapView(defaults: defaults, eventLocation: $draft.place)}
        .sheet(isPresented: $ui.showMessageScreen) {addMessageView}
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
    }

    private var cardBody: some View {
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
        .morphPopupOpen(ui.timePopupOpenDelayed || ui.typePopupOpenDelayed) //legacy: gated the morph's old Hide button
        .hideTabBar(hideBar: isInviteResponse)
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
