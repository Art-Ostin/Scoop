import SwiftUI

struct SendInviteContainer: View {

    static let screenMargin: CGFloat = 8
    static let contentPadding: CGFloat = 24

    //Injected
    @Binding var draft: EventFieldsDraft
    let name: String
    let isInviteResponse: Bool
    let defaults: DefaultsManaging
    let onSendInvite: () -> Void

    //Local view state
    @State private var ui = TimeAndPlaceUIState()

    var body: some View {
        VStack(spacing: 0) {
            InviteRowContainer(ui: ui, draft: $draft)
            sendButton
        }
        .task(id: ui.activePopup) { await ui.syncDelayedPopup() }
        .fullScreenCover(isPresented: $ui.showMapView) {MapView(defaults: defaults, eventLocation: $draft.place)}
        .sheet(isPresented: $ui.showMessageScreen) {
            NavigationStack {
                AddMessageView(message: $draft.message, isRespondMessage: false, eventType: $draft.type)
            }
        }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
        .padding(.horizontal, Self.contentPadding)
    }
}

//Key Components
extension SendInviteContainer {
    
    private var sendButton: some View {
        let label = Text("Invite \(name)")
            .font(.body(18, .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)

        return Group {
            if draft.isComplete {
                ScoopButton(style: .tinted(.textAccent, shadow: nil), shape: Capsule(), action: onSendInvite) {
                    label
                }
            } else {
                label
                    .background(Color.fillGray, in: Capsule())
            }
        }
        .opacity(ui.isPopupOpenDelayed() ? 0.4 : 1)
        .allowsHitTesting(draft.isComplete)
        .padding(.top, 4)
    }
}
