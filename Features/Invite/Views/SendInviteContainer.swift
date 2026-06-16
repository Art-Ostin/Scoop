import SwiftUI


//Vertical spacing here is adaptive. Therefore, it is controlled by the type, time, place padding not the vertical stacks

struct SendInviteContainer: View {
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
        .overlay(alignment: .topLeading) { clearAndInfoButtons }
        .modifier(InviteCardBackground())
        
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
            MapDivider()
            InviteTimeRow(showTimePopup: ui.binding(for: .time), proposedTimes: $draft.time, type: draft.type)
            MapDivider()
            InvitePlaceRow(eventLocation: $draft.place, showMapView: $ui.showMapView, isMultipleTimes: draft.time.dates.count > 1)
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
            .padding(.vertical, 24)
            .inviteCardBackground(color: .grayText) //Uses same background as respondCard
    }
}




//Old code no longer needed
/*
 
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

 
 
 
 .overlay(alignment: .top) {messageOverlay}

 private var messageOverlay: some View {
     let dayCount = draft.time.dates.count
     return SelectTimeMessage(type: draft.type, dayCount: dayCount, showTimePopup: ui.activePopup == .time, isCardMessage: true)
 }

 
 private var showTwoDays: Bool {
     (draft.type == .drink || draft.type == .doubleDate) &&
     ui.activePopup != .type &&
     ((ui.activePopup == .time && draft.time.dates.count < 2) || draft.time.dates.count == 1)
 }


 */
