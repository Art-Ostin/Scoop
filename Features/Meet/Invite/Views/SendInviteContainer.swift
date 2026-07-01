import SwiftUI


//Vertical spacing here is adaptive. Therefore, it is controlled by the type, time, place padding not the vertical stacks

struct SendInviteContainer: View {
    
    //0. Base gap from each screen edge to the card. Passed to the morph as the entrance-fallback
    static let screenMargin: CGFloat = 28

    //1. Controls what popup is showing or not
    @State var ui = TimeAndPlaceUIState()

    //2. The draft holds, proposedTimes, message, time and place, modified in this view
    @Binding var draft: EventFieldsDraft
    @Binding var showConfirmScreen: Bool

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
                .opacity(ui.typePopupOpenDelayed ? 0.4 : 1)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) { clearAndInfoButtons }
        .modifier(InviteCardBackground())
        .padding(.horizontal, cardMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .animation(.spring(duration: 0.3), value: [Double(cardMargin), Double(ui.messageLineCount)])
        .task(id: ui.timePopupOpen) { await addTimePopupDelay() }
        .task(id: ui.typePopupOpen) { await addTypePopupDelay()}
        .morphPopupOpen(ui.timePopupOpenDelayed || ui.typePopupOpenDelayed) //hide the morph's floating Hide button while a popup is open
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
            Text(isInviteResponse ? "Send New Invite" : "Meet \(name)")
                .font(.title(24))
        }
    }

    private var timePlaceAndType: some View {
        VStack(spacing: 0) {
            InviteTypeRow(ui: ui, type: $draft.type, unparsedMessage: $draft.message)
                .frame(height: 80, alignment: .center)
            LightDivider()
            InviteTimeRow(ui: ui, proposedTimes: $draft.time)
                .frame(height: 83, alignment: .center)//Fine Tuned Height Kep
            LightDivider()
            InvitePlaceRow(ui: ui, eventLocation: $draft.place, showMapView: $ui.showMapView, isMultipleTimes: draft.time.dates.count > 1)
                .frame(height: 80, alignment: .center)//Computed height, so doesn't change when I add a place
        }
        .zIndex(1) //so pop ups always appear above the Action Button
    }
    
    private var addMessageView: some View {
        NavigationStack {
            AddMessageView(message: $draft.message, isRespondMessage: false, eventType: $draft.type)
        }
    }
}

extension SendInviteContainer {
    
    private var inviteTypeRow: some View {
        VStack {
            InviteTypeRow(ui: ui, type: $draft.type, unparsedMessage: $draft.message)
            Spacer(minLength: 0)
            LightDivider()
        }
        .frame(height: 50, alignment: .top)
    }
    
    

    
    
}




struct InviteCardBackground: ViewModifier {
    // Dominant color extracted from the morph's source image, exposed here for a second background.
    @Environment(\.inviteCardTint) private var tint

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 20)//Slightly closer as Circle givesweird measurements
            // Tint wash first, so it lands ABOVE the opaque appCanvas but below the content.
            .background(tint.opacity(0.1), in: .rect(cornerRadius: 36, style: .continuous))
            .inviteCardBackground() //appCanvas fill sits behind the wash
            .padding(.top, 96)
    }
}




/*
 CirclePhoto(image: image, showShadow: false, height: 30)
 .padding(.top, 6) //Gives illusion of being identical because of Circle Button
 .padding(.bottom, draft.place == nil ? 9 : 14) //Fine tune so exact same

 */
